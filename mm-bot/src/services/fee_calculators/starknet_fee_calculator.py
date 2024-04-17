from starknet_py.hash.selector import get_selector_from_name

from config import constants
from models.order import Order
from services import starknet
from services.ethereum import get_gas_price
from services.fee_calculators.fee_calculator import FeeCalculator


class StarknetFeeCalculator(FeeCalculator):

    def estimate_claim_payment_fee(self) -> int:
        """
        Due to the deposit does not exist on ethereum at this point,
        we cannot estimate the gas fee of the claim payment transaction
        So we will use fixed values for the gas
        """
        eth_claim_payment_gas = 94_642  # TODO this is a fixed value, if the contract changes, this should be updated
        return eth_claim_payment_gas * get_gas_price()

    async def estimate_message_fee(self, order: Order) -> int:
        """
        Estimate the message fee for the claim payment transaction
        on Starknet. It is used as value in the transaction.
        """
        from_address = constants.ETHEREUM_CONTRACT_ADDRESS
        to_address = constants.STARKNET_CONTRACT_ADDRESS
        entry_point_selector = hex(get_selector_from_name("claim_payment"))
        payload = [
            hex(order.order_id),
            "0x0",
            order.recipient_address,
            hex(order.get_int_amount()),
            "0x0"
        ]
        return await starknet.estimate_message_fee(from_address, to_address, entry_point_selector, payload)
