import asyncio

from src.models.network import Network
from src.services import starknet
from src.services.processors.catch_up_orders_processor import CatchUpOrdersProcessor


class AcceptedBlocksOrdersProcessor(CatchUpOrdersProcessor):

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
