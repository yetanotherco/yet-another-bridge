import asyncio
import logging

import schedule

from config import constants
from config.database_config import get_db
from config.logging_config import setup_logger
from models.network import Network
from models.order import Order
from models.order_status import OrderStatus
from persistence.block_dao import BlockDao
from persistence.error_dao import ErrorDao
from persistence.order_dao import OrderDao
from services import ethereum
from services import starknet
from services.executors.order_executor import OrderExecutor
from services.indexers.starknet_order_indexer import StarknetOrderIndexer
from services.overall_fee_calculator import estimate_overall_fee
from services.order_service import OrderService
from services.payment_claimer.ethereum_payment_claimer import EthereumPaymentClaimer
from services.payment_claimer.herodotus_payment_claimer import HerodotusPaymentClaimer
from services.payment_claimer.payment_claimer import PaymentClaimer
from services.processors.orders_processor import OrdersProcessor

setup_logger()
logger = logging.getLogger(__name__)
SLEEP_TIME = 5
PROCESS_NO_BALANCE_ORDERS_MINUTES_TIMER = 5
PROCESS_ACCEPTED_BLOCKS_MINUTES_TIMER = 5
MAX_ETH_TRANSFER_WEI = 100000000000000000  # TODO move to env variable


def using_herodotus():
    return constants.PAYMENT_CLAIMER == "herodotus"


payment_claimer: PaymentClaimer = HerodotusPaymentClaimer() if using_herodotus() else EthereumPaymentClaimer()


async def run():
    logger.info(f"[+] Listening events on starknet")
    order_dao = OrderDao(get_db())
    error_dao = ErrorDao(get_db())
    order_service = OrderService(order_dao, error_dao)
    block_dao = BlockDao(get_db())
    eth_lock = asyncio.Lock()
    herodotus_semaphore = asyncio.Semaphore(100)

    order_indexer = StarknetOrderIndexer(order_service)
    order_executor = OrderExecutor(order_service, payment_claimer, eth_lock, herodotus_semaphore, MAX_ETH_TRANSFER_WEI)
    orders_processor = OrdersProcessor(order_indexer, order_executor)

    (schedule.every(PROCESS_NO_BALANCE_ORDERS_MINUTES_TIMER).minutes
     .do(failed_orders_job, order_service, eth_lock, herodotus_semaphore))
    (schedule.every(PROCESS_ACCEPTED_BLOCKS_MINUTES_TIMER).minutes
     .do(set_order_events_from_accepted_blocks_job, order_service, block_dao, eth_lock, herodotus_semaphore))
    schedule.run_all()

    try:
        # Get all orders that are not completed from the db
        orders = order_service.get_incomplete_orders()
        for order in orders:
            create_order_task(order, order_service, eth_lock, herodotus_semaphore)
    except Exception as e:
        logger.error(f"[-] Error: {e}")

    while True:
        try:
            # Process new orders
            await orders_processor.process_orders()

            schedule.run_pending()
        except Exception as e:
            logger.error(f"[-] Error: {e}")

        await asyncio.sleep(SLEEP_TIME)


def process_order_events(order_events: list, order_service: OrderService,
                         eth_lock: asyncio.Lock, herodotus_semaphore: asyncio.Semaphore):
    for order_event in order_events:
        order_id = order_event.order_id
        origin_network = order_event.origin_network
        recipient_address = order_event.recipient_address
        amount = order_event.amount
        fee = order_event.fee
        set_order_tx_hash = order_event.set_order_tx_hash
        is_used = order_event.is_used

        if order_service.already_exists(order_id, origin_network):
            logger.debug(f"[+] Order already processed: [{origin_network} ~ {order_id}]")
            continue

        try:
            order = Order(order_id=order_id, origin_network=origin_network,
                          recipient_address=recipient_address, amount=amount, fee=fee,
                          set_order_tx_hash=set_order_tx_hash,
                          status=OrderStatus.COMPLETED if is_used else OrderStatus.PENDING)
            order = order_service.create_order(order)
            logger.debug(f"[+] New order: {order}")
        except Exception as e:
            logger.error(f"[-] Error: {e}")
            continue

        create_order_task(order, order_service, eth_lock, herodotus_semaphore)


def create_order_task(order: Order, order_service: OrderService, eth_lock: asyncio.Lock,
                      herodotus_semaphore: asyncio.Semaphore):
    asyncio.create_task(process_order(order, order_service, eth_lock, herodotus_semaphore),
                        name=f"Order-{order.order_id}")


async def process_order(order: Order, order_service: OrderService,
                        eth_lock: asyncio.Lock, herodotus_semaphore: asyncio.Semaphore):
    try:
        logger.info(f"[+] Processing order: {order}")
        # 1. Check if the order fee is enough
        if order.status is OrderStatus.PENDING:
            estimated_fee = await estimate_overall_fee(order)
            if order.get_int_fee() < estimated_fee:
                logger.error(f"[-] Order fee is too low: {order.get_int_fee()} < {estimated_fee}")
                order_service.set_order_dropped(order)
                return
            order_service.set_order_processing(order)

        # 1.5. Check if order amount is too high
        if order.amount > MAX_ETH_TRANSFER_WEI:
            logger.error(f"[-] Order amount is too high: {order.amount}")
            order_service.set_order_dropped(order)
            return

        # 2. Transfer eth on ethereum
        # (bridging is complete for the user)
        if order.status in [OrderStatus.PROCESSING, OrderStatus.TRANSFERRING]:
            async with eth_lock:
                if order.status is OrderStatus.PROCESSING:
                    await transfer(order, order_service)

                # 2.5. Wait for transfer
                if order.status is OrderStatus.TRANSFERRING:
                    await wait_transfer(order, order_service)

        if order.status in [OrderStatus.FULFILLED, OrderStatus.PROVING]:
            async with herodotus_semaphore if using_herodotus() else eth_lock:
                # 3. Call herodotus to prove
                # extra: validate w3.eth.get_storage_at(addr, pos) before calling herodotus
                if order.status is OrderStatus.FULFILLED:
                    await payment_claimer.send_payment_claim(order, order_service)

                # 4. Poll herodotus to check task status
                if order.status is OrderStatus.PROVING:
                    await payment_claimer.wait_for_payment_claim(order, order_service)

        # 5. Claim payment eth from starknet
        # (bridging is complete for the mm)
        if order.status is OrderStatus.PROVED:
            await payment_claimer.close_payment_claim(order, order_service)

        if order.status is OrderStatus.COMPLETED:
            logger.info(f"[+] Order {order.order_id} completed")
    except Exception as e:
        order_service.set_order_failed(order, str(e))


def failed_orders_job(order_service: OrderService,
                      eth_lock: asyncio.Lock, herodotus_semaphore: asyncio.Semaphore):
    asyncio.create_task(process_failed_orders(order_service, eth_lock, herodotus_semaphore), name="No-balance-orders")


async def process_failed_orders(order_service: OrderService,
                                eth_lock: asyncio.Lock, herodotus_semaphore: asyncio.Semaphore):
    try:
        logger.debug(f"[+] Processing no balance orders")
        orders = order_service.get_failed_orders()
        for order in orders:
            order_service.reset_failed_order(order)
            create_order_task(order, order_service, eth_lock, herodotus_semaphore)
    except Exception as e:
        logger.error(f"[-] Error: {e}")


def set_order_events_from_accepted_blocks_job(order_service: OrderService, block_dao: BlockDao,
                                              eth_lock: asyncio.Lock, herodotus_semaphore: asyncio.Semaphore):
    asyncio.create_task(process_orders_from_accepted_blocks(order_service, block_dao, eth_lock, herodotus_semaphore),
                        name="Accepted-blocks")


async def process_orders_from_accepted_blocks(order_service: OrderService, block_dao: BlockDao,
                                              eth_lock: asyncio.Lock, herodotus_semaphore: asyncio.Semaphore):
    try:
        latest_block = block_dao.get_latest_block(Network.STARKNET)
        order_events = await starknet.get_order_events(latest_block, "latest")
        process_order_events(order_events, order_service, eth_lock, herodotus_semaphore)
        if len(order_events) > 0:
            block_dao.update_latest_block(max(map(lambda x: x.block_number, order_events)), Network.STARKNET)
    except Exception as e:
        logger.error(f"[-] Error: {e}")


async def transfer(order: Order, order_service: OrderService):
    logger.info(f"[+] Transferring eth on ethereum")
    # in case it's processed on ethereum, but not processed on starknet
    tx_hash = await asyncio.to_thread(ethereum.transfer, order.order_id, order.recipient_address,
                                      order.get_int_amount())
    order_service.set_order_transferring(order, tx_hash)
    logger.info(f"[+] Transfer tx hash: {tx_hash.hex()}")


async def wait_transfer(order: Order, order_service: OrderService):
    await asyncio.to_thread(ethereum.wait_for_transaction_receipt, order.tx_hash)
    order_service.set_order_fulfilled(order)
    logger.info(f"[+] Transfer complete")


if __name__ == '__main__':
    asyncio.run(run())
