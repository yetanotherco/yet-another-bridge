import logging
from abc import ABC, abstractmethod

from persistence.block_dao import BlockDao
from services.executors.order_executor import OrderExecutor
from services.indexers.order_indexer import OrderIndexer


class CatchUpOrdersProcessor(ABC):

    def __init__(self, order_indexer: OrderIndexer,
                 order_executor: OrderExecutor,
                 block_dao: BlockDao):
        self.logger = logging.getLogger(__name__)
        self.order_indexer: OrderIndexer = order_indexer
        self.order_executor: OrderExecutor = order_executor
        self.block_dao: BlockDao = block_dao

    @abstractmethod
    async def process_orders(self):
        """

        """
        pass

    @abstractmethod
    def process_orders_job(self):
        """
        Process orders job for the scheduler
        """
        pass
