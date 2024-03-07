import asyncio
import logging

import schedule

from config import constants
from config.database_config import get_db
from config.logging_config import setup_logger
from persistence.block_dao import BlockDao
from persistence.error_dao import ErrorDao
from persistence.order_dao import OrderDao
from services.executors.order_executor import OrderExecutor
from services.indexers.starknet_order_indexer import StarknetOrderIndexer
from services.order_service import OrderService
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
    ethereum_sender = EthereumSender(order_service)

    order_indexer = StarknetOrderIndexer(order_service)
    order_executor = OrderExecutor(order_service, ethereum_sender, payment_claimer,
                                   eth_lock, herodotus_semaphore, MAX_ETH_TRANSFER_WEI)
    orders_processor = OrdersProcessor(order_indexer, order_executor)

    failed_orders_processor = FailedOrdersProcessor(order_executor, order_service)
    accepted_blocks_orders_processor = AcceptedBlocksOrdersProcessor(order_indexer, order_executor, block_dao)

    (schedule.every(PROCESS_NO_BALANCE_ORDERS_MINUTES_TIMER).minutes
     .do(failed_orders_processor.process_orders_job))
    (schedule.every(PROCESS_ACCEPTED_BLOCKS_MINUTES_TIMER).minutes
     .do(accepted_blocks_orders_processor.process_orders_job))

    schedule.run_all()

    try:
        # Get all orders that are not completed from the db
        orders = order_service.get_incomplete_orders()
        for order in orders:
            order_executor.execute(order)
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


if __name__ == '__main__':
    asyncio.run(run())
