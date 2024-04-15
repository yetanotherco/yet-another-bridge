import asyncio

from models.network import Network
from services import zksync
from services.processors.catch_up_orders_processor import CatchUpOrdersProcessor

# The maximum number of blocks that can be queried in a single request is 500.
# https://docs.blastapi.io/blast-documentation/apis-documentation/core-api/oktc/eth_getlogs#limits
BLOCK_BATCH_SIZE = 500


class LongRangeOrdersProcessor(CatchUpOrdersProcessor):

    async def process_orders(self):
        try:
            latest_block = self.block_dao.get_latest_block(Network.ZKSYNC)
            new_latest_block = await zksync.get_latest_block()

            for order_block in range(latest_block, new_latest_block, BLOCK_BATCH_SIZE):
                end_block = min(order_block + BLOCK_BATCH_SIZE, new_latest_block)
                orders = await self.order_indexer.get_orders(order_block, end_block)
                for order in orders:
                    self.order_executor.execute(order)
            self.block_dao.update_latest_block(new_latest_block, Network.ZKSYNC)
        except Exception as e:
            self.logger.error(f"[-] Error: {e}")

    def process_orders_job(self):
        asyncio.create_task(self.process_orders(),
                            name="Long Range Orders")
