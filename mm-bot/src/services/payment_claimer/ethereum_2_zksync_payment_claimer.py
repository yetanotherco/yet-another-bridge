import asyncio

from src.config import constants
from src.services import ethereum
from src.services.fee_calculators.zksync_fee_calculator import ZksyncFeeCalculator
from src.services.payment_claimer.payment_claimer import PaymentClaimer


class Ethereum2ZksyncPaymentClaimer(PaymentClaimer):

    def __init__(self, fee_calculator: ZksyncFeeCalculator):
        super().__init__()
        self.fee_calculator: ZksyncFeeCalculator = fee_calculator

    async def send_payment_claim(self, order, order_service):
        """
        Makes the payment claim on ethereum
        Sends a 'claimPaymentZKSync' transaction to ethereum smart contract
        """
        self.logger.info(f"[+] Sending payment claim tx to ethereum")
        order_id, recipient_address, amount = order.order_id, order.recipient_address, order.get_int_amount()
        value = await self.fee_calculator.estimate_message_fee(order)
        gas_limit = await self.fee_calculator.estimate_gas_limit(order)
        gas_per_pub_data_byte_limit = self.fee_calculator.estimate_gas_per_pub_data_byte_limit(order)
        tx_hash = await asyncio.to_thread(ethereum.claim_payment_zksync,
                                          order_id, recipient_address, amount, value, gas_limit, gas_per_pub_data_byte_limit)
        order_service.set_order_proving_ethereum(order, tx_hash)
        self.logger.info(f"[+] Payment claim tx hash: {tx_hash.hex()}")

    async def wait_for_payment_claim(self, order, order_service):
        """
        Waits for the payment claim transaction to be confirmed on ethereum
        """
        await asyncio.to_thread(ethereum.wait_for_transaction_receipt, order.claim_tx_hash)
        order_service.set_order_proved(order)
        self.logger.info(f"[+] Claim payment tx confirmed")

    async def close_payment_claim(self, order, order_service):
        """
        Closes the payment claim setting the order as completed
        # TODO it should be checking the status in the escrow instead of the payment registry
        # TODO this is why this code is repeated in the other payment claimers
        """
        retries = 0
        while retries < constants.MAX_RETRIES:
            if await asyncio.to_thread(ethereum.get_is_used_order,
                                       order.order_id, order.recipient_address, order.get_int_amount(), order.origin_network.value):
                break
            retries += 1
            await asyncio.sleep(10)
        self.logger.info(f"[+] Claim payment complete")
        order_service.set_order_completed(order)
