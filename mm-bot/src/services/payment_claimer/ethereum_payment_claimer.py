import asyncio

from config import constants
from models.order import Order
from services import ethereum
from services.fee_calculators.starknet_fee_calculator import StarknetFeeCalculator
from services.order_service import OrderService
from services.payment_claimer.payment_claimer import PaymentClaimer


class EthereumPaymentClaimer(PaymentClaimer):

    def __init__(self, fee_calculator: StarknetFeeCalculator):
        super().__init__()
        self.fee_calculator: StarknetFeeCalculator = fee_calculator

    async def send_payment_claim(self, order: Order, order_service: OrderService):  # TODO remove order_service
        """
        Makes the payment claim on ethereum
        Sends a 'claimPayment' transaction to ethereum smart contract
        """
        self.logger.info(f"[+] Sending payment claim tx to ethereum")
        order_id, recipient_address, amount = order.order_id, order.recipient_address, order.get_int_amount()
        value = await self.fee_calculator.estimate_message_fee(order)
        tx_hash = await asyncio.to_thread(ethereum.claim_payment,
                                          order_id, recipient_address, amount, value)
        order_service.set_order_proving_ethereum(order, tx_hash)
        self.logger.info(f"[+] Payment claim tx hash: {tx_hash.hex()}")

    async def wait_for_payment_claim(self, order: Order, order_service: OrderService):  # TODO remove order_service
        """
        Waits for the payment claim transaction to be confirmed on ethereum
        """
        await asyncio.to_thread(ethereum.wait_for_transaction_receipt, order.claim_tx_hash)
        order_service.set_order_proved(order)
        self.logger.info(f"[+] Claim payment tx confirmed")

    async def close_payment_claim(self, order: Order, order_service: OrderService):  # TODO remove order_service
        """
        Closes the payment claim setting the order as completed
        """
        retries = 0
        while retries < constants.MAX_RETRIES:
            if await asyncio.to_thread(ethereum.get_is_used_order,
                                       order.order_id, order.recipient_address, order.get_int_amount()):
                break
            retries += 1
            await asyncio.sleep(10)
        self.logger.info(f"[+] Claim payment complete")
        order_service.set_order_completed(order)
