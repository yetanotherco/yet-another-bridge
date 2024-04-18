import asyncio
import logging
from abc import ABC, abstractmethod
from web3 import Web3

from models.order import Order
from services.ethereum import create_transfer, estimate_transaction_fee, get_gas_price


class FeeCalculator(ABC):

    def __init__(self):
        self.logger = logging.getLogger(__name__)

    async def estimate_overall_fee(self, order: Order) -> int:
        """
        Operational cost per order done by the market maker.
        This includes:
            calling the transfer (from PaymentRegistry) +
            claimPayment (from PaymentRegistry) +
            msg fee paid to L2 (when calling claim_payment)
        """
        transfer_fee = await asyncio.to_thread(self.estimate_transfer_fee, order)
        message_fee = await self.estimate_message_fee(order)
        claim_payment_fee = self.estimate_claim_payment_fee()
        overall_fee = transfer_fee + message_fee + claim_payment_fee
        self.logger.info(f"Overall fee: {overall_fee} [received: {order.get_int_fee()}]")
        return overall_fee

    def estimate_transfer_fee(self, order: Order) -> int:
        deposit_id = Web3.to_int(order.order_id)
        destination_address = Web3.to_checksum_address(order.recipient_address)
        amount = Web3.to_int(order.get_int_amount())
        chain_id = order.origin_network.value

        unsent_tx, signed_tx = create_transfer(deposit_id, destination_address, amount, chain_id)
        # TODO rename parameters to order_id
        return estimate_transaction_fee(unsent_tx)

    @abstractmethod
    def estimate_claim_payment_fee(self) -> int:
        """
        """
        pass

    @abstractmethod
    async def estimate_message_fee(self, order: Order) -> int:
        pass

