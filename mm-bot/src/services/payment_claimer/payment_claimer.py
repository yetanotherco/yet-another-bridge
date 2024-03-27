import logging
from abc import ABC, abstractmethod

from models.order import Order
from services.order_service import OrderService


class PaymentClaimer(ABC):

    def __init__(self):  # TODO add order_service as a parameter
        self.logger = logging.getLogger(__name__)

    """
    """
    @abstractmethod
    async def send_payment_claim(self, order: Order, order_service: OrderService):  # TODO remove order_service
        pass

    """
    """
    @abstractmethod
    async def wait_for_payment_claim(self, order: Order, order_service: OrderService):  # TODO remove order_service
        pass

    """
    """
    @abstractmethod
    async def close_payment_claim(self, order: Order, order_service: OrderService):  # TODO remove order_service
        pass
