from models.order import Order
from models.set_order_event import SetOrderEvent
from services import zksync
from services.indexers.order_indexer import OrderIndexer


class ZksyncOrderIndexer(OrderIndexer):

    async def get_orders(self, from_block, to_block) -> list[Order]:
        """
        Get orders from the escrow
        """
        set_order_events: list[SetOrderEvent] = await zksync.get_set_order_events(from_block, to_block)
        return self.save_orders(set_order_events)

    async def get_new_orders(self) -> list[Order]:
        """
        Get new orders from the escrow
        On ZKSync we index new orders from the last 10 blocks
        """
        block_number = await zksync.get_latest_block()
        from_block = max(block_number - 10, 1)
        to_block = block_number
        return await self.get_orders(from_block, to_block)
