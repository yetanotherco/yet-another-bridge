import asyncio
import logging

from services import ethereum
from services.order_service import OrderService


class EthereumSender:

    def __init__(self, order_service: OrderService):
        self.logger = logging.getLogger(__name__)
        self.order_service: OrderService = order_service

    async def transfer(self, order):
        """

        """
        self.logger.info(f"[+] Transferring eth on ethereum")
        tx_hash = await asyncio.to_thread(ethereum.transfer, order.order_id, order.recipient_address,
                                          order.get_int_amount())
        self.order_service.set_order_transferring(order, tx_hash)
        self.logger.info(f"[+] Transfer tx hash: {tx_hash.hex()}")

    async def wait_transfer(self, order):
        """

        """
        await asyncio.to_thread(ethereum.wait_for_transaction_receipt, order.tx_hash)
        self.order_service.set_order_fulfilled(order)
        self.logger.info(f"[+] Transfer complete")
