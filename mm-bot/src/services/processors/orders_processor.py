import logging

from src.services.executors.order_executor import OrderExecutor
from src.services.indexers.order_indexer import OrderIndexer


class OrdersProcessor:
    def __init__(self, order_indexer: OrderIndexer,
                 order_executor: OrderExecutor):
        """
        Each processor will have:
        - an indexer to get new orders
        - an executor to process orders
        """
        self.logger = logging.getLogger(__name__)
        self.order_indexer: OrderIndexer = order_indexer
        self.order_executor: OrderExecutor = order_executor

    async def process_orders(self):
        """

        """
        orders = await self.order_indexer.get_new_orders()
        for order in orders:
            self.order_executor.execute(order)
