import asyncio

from starknet_py.hash.selector import get_selector_from_name

from config import constants
from models.order import Order
from services import ethereum, starknet
from services.order_service import OrderService
from services.payment_claimer.payment_claimer import PaymentClaimer


class EthereumPaymentClaimer(PaymentClaimer):

    async def send_payment_claim(self, order: Order, order_service: OrderService):
        """
        Makes the payment claim on ethereum
        Sends a 'claimPayment' transaction to ethereum smart contract
        """
        self.logger.info(f"[+] Sending payment claim tx to ethereum")
        order_id, recipient_address, amount = order.order_id, order.recipient_address, order.get_int_amount()
        value = await self.estimate_claim_payment_fallback_message_fee(order_id, recipient_address, amount)
        tx_hash = await asyncio.to_thread(ethereum.claim_payment,
                                          order_id, recipient_address, amount, value)
        order_service.set_order_proving_ethereum(order, tx_hash)
        self.logger.info(f"[+] Payment claim tx hash: {tx_hash.hex()}")

    @staticmethod
    async def estimate_claim_payment_fallback_message_fee(order_id, recipient_address, amount):
        from_address = constants.ETHEREUM_CONTRACT_ADDRESS
        to_address = constants.STARKNET_CONTRACT_ADDRESS
        entry_point_selector = hex(get_selector_from_name("claim_payment"))
        payload = [
            hex(order_id),
            "0x0",
            recipient_address,
            hex(amount),
            "0x0"
        ]
        return await starknet.estimate_message_fee(from_address, to_address, entry_point_selector, payload)

    async def wait_for_payment_claim(self, order: Order, order_service: OrderService):
        """
        Waits for the payment claim transaction to be confirmed on ethereum
        """
        await asyncio.to_thread(ethereum.wait_for_transaction_receipt, order.eth_claim_tx_hash)
        order_service.set_order_proved(order)
        self.logger.info(f"[+] Claim payment tx confirmed")

    async def close_payment_claim(self, order: Order, order_service: OrderService):
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
