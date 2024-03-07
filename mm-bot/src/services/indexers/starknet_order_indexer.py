from models.order import Order
from models.order_status import OrderStatus
from services import starknet
from services.indexers.order_indexer import OrderIndexer
from services.order_service import OrderService
from services.starknet import SetOrderEvent


class StarknetOrderIndexer(OrderIndexer):

    def __init__(self, order_service: OrderService):
        super().__init__()
        self.order_service = order_service

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

    def save_orders(self, set_order_events: list[SetOrderEvent]) -> list[Order]:
        """
        Save orders to the database if not already saved
        """
        orders: list[Order] = []
        for set_order_event in set_order_events:
            order_id = set_order_event.order_id
            origin_network = set_order_event.origin_network
            recipient_address = set_order_event.recipient_address
            amount = set_order_event.amount
            fee = set_order_event.fee
            set_order_tx_hash = set_order_event.set_order_tx_hash
            is_used = set_order_event.is_used

            if self.order_service.already_exists(order_id, origin_network):
                self.logger.debug(f"[+] Order already processed: [{origin_network} ~ {order_id}]")
                continue

            try:
                order = Order(order_id=order_id, origin_network=origin_network,
                              recipient_address=recipient_address, amount=amount, fee=fee,
                              set_order_tx_hash=set_order_tx_hash,
                              status=OrderStatus.COMPLETED if is_used else OrderStatus.PENDING)
                order = self.order_service.create_order(order)
                orders.append(order)
                self.logger.debug(f"[+] New order: {order}")
            except Exception as e:
                self.logger.error(f"[-] Error: {e}")
                continue
        return orders
