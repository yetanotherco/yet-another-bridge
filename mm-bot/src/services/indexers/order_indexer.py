import logging
from abc import ABC, abstractmethod

from src.models.order import Order
from src.models.set_order_event import SetOrderEvent
from src.services.order_service import OrderService


class OrderIndexer(ABC):

    def __init__(self, order_service: OrderService):
        self.logger = logging.getLogger(__name__)
        self.order_service = order_service

    @abstractmethod
    async def get_orders(self, from_block, to_block) -> list[Order]:
        """
        Get orders from the escrow
        """
        pass

    @abstractmethod
    async def get_new_orders(self) -> list[Order]:
        """
        Get new orders from the escrow
        Depending on the indexer implementation, it will use correct
        parameters to set from_block and to_block
        """
        pass

    def save_orders(self, set_order_events: list[SetOrderEvent]) -> list[Order]:
        """
        Save orders to the database if not already saved
        This is a common implementation for all indexers
        """
        orders: list[Order] = []
        for set_order_event in set_order_events:
            if self.order_service.already_exists(set_order_event.order_id, set_order_event.origin_network):
                self.logger.debug(f"[+] Order already processed: [{set_order_event.origin_network} ~ {set_order_event.order_id}]")
                continue

            try:
                order = Order.from_set_order_event(set_order_event)
                order = self.order_service.create_order(order)
                orders.append(order)
                self.logger.debug(f"[+] New order: {order}")
            except Exception as e:
                self.logger.error(f"[-] Error: {e}")
                continue
        return orders

