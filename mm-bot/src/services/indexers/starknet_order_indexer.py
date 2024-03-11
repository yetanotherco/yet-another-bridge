from models.order import Order
from services import starknet
from services.indexers.order_indexer import OrderIndexer
from services.starknet import SetOrderEvent


class StarknetOrderIndexer(OrderIndexer):

    async def get_orders(self, from_block, to_block) -> list[Order]:
        """
        Get orders from the escrow
        """
        set_order_events: list[SetOrderEvent] = await starknet.get_order_events(from_block, to_block)
        return self.save_orders(set_order_events)

    async def get_new_orders(self) -> list[Order]:
        """
        Get new orders from the escrow
        On Starknet, we use pending as from_block and to_block
        """
        return await self.get_orders("pending", "pending")
