import asyncio
import logging

import schedule

from config import constants
from config.database_config import get_db
from config.logging_config import setup_logger
from models.network import Network
from persistence.block_dao import BlockDao
from persistence.error_dao import ErrorDao
from persistence.order_dao import OrderDao
from services.executors.order_executor import OrderExecutor
from services.fee_calculators.starknet_fee_calculator import StarknetFeeCalculator
from services.fee_calculators.zksync_fee_calculator import ZksyncFeeCalculator
from services.indexers.starknet_order_indexer import StarknetOrderIndexer
from services.indexers.zksync_order_indexer import ZksyncOrderIndexer
from services.order_service import OrderService
from services.payment_claimer.ethereum_2_zksync_payment_claimer import Ethereum2ZksyncPaymentClaimer
from services.payment_claimer.ethereum_payment_claimer import EthereumPaymentClaimer
from services.payment_claimer.herodotus_payment_claimer import HerodotusPaymentClaimer
from services.payment_claimer.payment_claimer import PaymentClaimer
from services.processors.accepted_blocks_orders_processor import AcceptedBlocksOrdersProcessor
from services.processors.failed_orders_processor import FailedOrdersProcessor
from services.processors.orders_processor import OrdersProcessor
from services.senders.ethereum_sender import EthereumSender

setup_logger()
logger = logging.getLogger(__name__)
SLEEP_TIME = 5
PROCESS_FAILED_ORDERS_MINUTES_TIMER = 5
PROCESS_ACCEPTED_BLOCKS_MINUTES_TIMER = 5
MAX_ETH_TRANSFER_WEI = 100000000000000000  # TODO move to env variable


def using_herodotus():
    return constants.PAYMENT_CLAIMER == "herodotus"


async def run():
    logger.info(f"[+] Listening events")
    # Initialize DAOs
    order_dao = OrderDao(get_db())
    error_dao = ErrorDao(get_db())
    block_dao = BlockDao(get_db())

    # Initialize services
    order_service = OrderService(order_dao, error_dao)

    # Initialize concurrency primitives
    eth_lock = asyncio.Lock()
    herodotus_semaphore = asyncio.Semaphore(100)

    # Initialize fee calculator
    starknet_fee_calculator = StarknetFeeCalculator()
    zksync_fee_calculator = ZksyncFeeCalculator()

    # Initialize sender and payment claimer
    ethereum_sender = EthereumSender(order_service)
    starknet_payment_claimer: PaymentClaimer = HerodotusPaymentClaimer() if using_herodotus() \
        else EthereumPaymentClaimer(starknet_fee_calculator)
    zksync_payment_claimer: PaymentClaimer = Ethereum2ZksyncPaymentClaimer(zksync_fee_calculator)

    # Initialize starknet indexer and processor
    starknet_order_indexer = StarknetOrderIndexer(order_service)
    starknet_order_executor = OrderExecutor(order_service, ethereum_sender, starknet_payment_claimer,
                                            starknet_fee_calculator, eth_lock, herodotus_semaphore,
                                            MAX_ETH_TRANSFER_WEI)
    starknet_orders_processor = OrdersProcessor(starknet_order_indexer, starknet_order_executor)

    # Initialize ZkSync indexer and processor
    zksync_order_indexer = ZksyncOrderIndexer(order_service)
    zksync_order_executor = OrderExecutor(order_service, ethereum_sender, zksync_payment_claimer,
                                          zksync_fee_calculator, eth_lock, herodotus_semaphore,
                                          MAX_ETH_TRANSFER_WEI)
    zksync_order_processor = OrdersProcessor(zksync_order_indexer, zksync_order_executor)

    # Initialize failed orders processor for starknet
    failed_orders_processor = FailedOrdersProcessor(starknet_order_executor, order_service)

    # Initialize accepted blocks orders processor for starknet
    accepted_blocks_orders_processor = AcceptedBlocksOrdersProcessor(starknet_order_indexer, starknet_order_executor,
                                                                     block_dao)

    (schedule.every(PROCESS_FAILED_ORDERS_MINUTES_TIMER).minutes
     .do(failed_orders_processor.process_orders_job))
    (schedule.every(PROCESS_ACCEPTED_BLOCKS_MINUTES_TIMER).minutes
     .do(accepted_blocks_orders_processor.process_orders_job))

    try:
        # Get all orders that are not completed from the db
        orders = order_service.get_incomplete_orders()
        for order in orders:
            if order.origin_network is Network.STARKNET:
                starknet_order_executor.execute(order)
            elif order.origin_network is Network.ZKSYNC:
                zksync_order_executor.execute(order)
    except Exception as e:
        logger.error(f"[-] Error: {e}")

    schedule.run_all()

    while True:
        try:
            # Process new orders
            tasks = [asyncio.create_task(starknet_orders_processor.process_orders(), name="Starknet_Processor"),
                     asyncio.create_task(zksync_order_processor.process_orders(), name="ZkSync_Processor")]
            await asyncio.gather(*tasks)

            schedule.run_pending()
        except Exception as e:
            logger.error(f"[-] Error: {e}")

        await asyncio.sleep(SLEEP_TIME)


if __name__ == '__main__':
    asyncio.run(run())
