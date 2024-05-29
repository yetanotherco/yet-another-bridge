import asyncio
import logging

from src.models.network import Network
from src.services.executors.order_executor import OrderExecutor
from src.services.order_service import OrderService


class FailedOrdersProcessor:

    def __init__(self, order_executor: OrderExecutor,
                 order_service: OrderService):
        self.logger = logging.getLogger(__name__)
        self.order_executor: OrderExecutor = order_executor
        self.order_service: OrderService = order_service

    async def process_orders(self):
        """
        Process failed orders stored in the database
        """
        try:
            orders = self.order_service.get_failed_orders()
            for order in orders:
                if order.origin_network is Network.STARKNET:
                    self.order_service.reset_failed_order(order)
                    self.order_executor.execute(order)
                # TODO add support for ZkSync
        except Exception as e:
            self.logger.error(f"[-] Error: {e}")

    def process_orders_job(self):
        """
        Process orders job for the scheduler
        """
        asyncio.create_task(self.process_orders(),
                            name="Failed Orders")
