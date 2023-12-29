import logging
from abc import ABC, abstractmethod

from models.order import Order
from persistence.order_dao import OrderDao


class Withdrawer(ABC):

    def __init__(self):
        self.logger = logging.getLogger(__name__)

    """
    """
    @abstractmethod
    async def send_withdraw(self, order: Order, order_dao: OrderDao):
        pass

    """
    """
    @abstractmethod
    async def wait_for_withdraw(self, order: Order, order_dao: OrderDao):
        pass

    """
    """
    @abstractmethod
    async def close_withdraw(self, order: Order, order_dao: OrderDao):
        pass
