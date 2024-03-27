import asyncio
import logging

from models.network import Network
from persistence.block_dao import BlockDao
from services import starknet
from services.executors.order_executor import OrderExecutor
from services.indexers.order_indexer import OrderIndexer


class AcceptedBlocksOrdersProcessor:

    def __init__(self, order_indexer: OrderIndexer,
                 order_executor: OrderExecutor,
                 block_dao: BlockDao):
        self.logger = logging.getLogger(__name__)
        self.order_indexer: OrderIndexer = order_indexer
        self.order_executor: OrderExecutor = order_executor
        self.block_dao: BlockDao = block_dao

    async def process_orders(self, ):
        """

        """
        try:
            latest_block = self.block_dao.get_latest_block(Network.STARKNET)
            new_latest_block = await starknet.get_latest_block()
            orders = await self.order_indexer.get_orders(latest_block, new_latest_block)
            for order in orders:
                self.order_executor.execute(order)
            self.block_dao.update_latest_block(new_latest_block, Network.STARKNET)
        except Exception as e:
            self.logger.error(f"[-] Error: {e}")

    def process_orders_job(self):
        """
        Process orders job for the scheduler
        """
        asyncio.create_task(self.process_orders(),
                            name="Accepted Blocks")
