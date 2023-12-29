import asyncio
import logging

from config import constants
from config.database_config import get_db
from config.logging_config import setup_logger
from models.order import Order
from models.order_status import OrderStatus
from persistence.block_dao import BlockDao
from persistence.order_dao import OrderDao
from services import ethereum
from services import starknet
from services.withdrawer.ethereum_withdrawer import EthereumWithdrawer
from services.withdrawer.herodotus_withdrawer import HerodotusWithdrawer
from services.withdrawer.withdrawer import Withdrawer

setup_logger()
logger = logging.getLogger(__name__)
SLEEP_TIME = 5


def using_herodotus():
    return constants.WITHDRAWER == "herodotus"


withdrawer: Withdrawer = HerodotusWithdrawer() if using_herodotus() else EthereumWithdrawer()


async def run():
    logger.info(f"[+] Listening events on starknet")
    order_dao = OrderDao(get_db())
    block_dao = BlockDao(get_db())
    eth_lock = asyncio.Lock()
    herodotus_semaphore = asyncio.Semaphore(100)

    try:
        # 1 Get all orders that are not completed from the db
        orders = order_dao.get_incomplete_orders()
        for order in orders:
            create_order_task(order, order_dao, eth_lock, herodotus_semaphore)

        # 2. Get orders from missed blocks (if any) after the last time the mm was running
        latest_block = block_dao.get_latest_block()
        order_events = await starknet.get_order_events(latest_block, "latest")
        process_order_events(order_events, order_dao, eth_lock, herodotus_semaphore)
        if len(order_events) > 0:
            block_dao.update_latest_block(max(map(lambda x: x.block_number, order_events)))

        while True:
            # 3. Listen event on starknet
            set_order_events: list = await starknet.get_order_events("pending", "pending")

            # 4. Process events (create order, transfer eth, prove, withdraw eth)
            process_order_events(set_order_events, order_dao, eth_lock, herodotus_semaphore)

            # 5. Update latest block
            block_dao.update_latest_block(await starknet.get_latest_block())

            await asyncio.sleep(SLEEP_TIME)
    except Exception as e:
        logger.error(f"[-] Error: {e}")


def process_order_events(order_events: list, order_dao: OrderDao,
                         eth_lock: asyncio.Lock, herodotus_semaphore: asyncio.Semaphore):
    for order_event in order_events:
        order_id = order_event.order_id
        recipient_addr = order_event.recipient_address
        amount = order_event.amount
        is_used = order_event.is_used

        if order_dao.already_exists(order_id):
            logger.debug(f"[+] Order already processed: {order_id}")
            continue

        try:
            order = Order(order_id=order_id, recipient_address=recipient_addr, amount=amount,
                          status=OrderStatus.COMPLETED if is_used else OrderStatus.PENDING)
            order = order_dao.create_order(order)
            logger.info(f"[+] New order: {order}")
        except Exception as e:
            logger.error(f"[-] Error: {e}")
            continue

        create_order_task(order, order_dao, eth_lock, herodotus_semaphore)


def create_order_task(order: Order, order_dao: OrderDao, eth_lock: asyncio.Lock,
                      herodotus_semaphore: asyncio.Semaphore):
    asyncio.create_task(process_order(order, order_dao, eth_lock, herodotus_semaphore), name=f"Order-{order.order_id}")


async def process_order(order: Order, order_dao: OrderDao,
                        eth_lock: asyncio.Lock, herodotus_semaphore: asyncio.Semaphore):
    if order.status is OrderStatus.PENDING:
        order_dao.set_order_processing(order)

    # 2. Transfer eth on ethereum
    # (bridging is complete for the user)
    if order.status in [OrderStatus.PROCESSING, OrderStatus.TRANSFERRING]:
        async with eth_lock:
            if order.status is OrderStatus.PROCESSING:
                try:
                    await transfer(order, order_dao)
                except Exception as e:
                    logger.error(f"[-] Transfer failed: {e}")

            # 2.5. Wait for transfer
            if order.status is OrderStatus.TRANSFERRING:
                await wait_transfer(order, order_dao)

    if order.status in [OrderStatus.FULFILLED, OrderStatus.PROVING]:
        async with herodotus_semaphore if using_herodotus() else eth_lock:
            # 3. Call herodotus to prove
            # extra: validate w3.eth.get_storage_at(addr, pos) before calling herodotus
            if order.status is OrderStatus.FULFILLED:
                await withdrawer.send_withdraw(order, order_dao)

            # 4. Poll herodotus to check task status
            if order.status is OrderStatus.PROVING:
                await withdrawer.wait_for_withdraw(order, order_dao)

    # 5. Withdraw eth from starknet
    # (bridging is complete for the mm)
    if order.status is OrderStatus.PROVED:
        await withdrawer.close_withdraw(order, order_dao)

    if order.status is OrderStatus.COMPLETED:
        logger.info(f"[+] Order {order.order_id} completed")


async def transfer(order: Order, order_dao: OrderDao):
    logger.info(f"[+] Transferring eth on ethereum")
    # in case it's processed on ethereum, but not processed on starknet
    tx_hash = await asyncio.to_thread(ethereum.transfer, order.order_id, order.recipient_address,
                                      order.get_int_amount())
    order_dao.set_order_transferring(order, tx_hash)
    logger.info(f"[+] Transfer tx hash: {tx_hash.hex()}")


async def wait_transfer(order: Order, order_dao: OrderDao):
    await asyncio.to_thread(ethereum.wait_for_transaction_receipt, order.tx_hash)
    order_dao.set_order_fulfilled(order)
    logger.info(f"[+] Transfer complete")


if __name__ == '__main__':
    asyncio.run(run())
