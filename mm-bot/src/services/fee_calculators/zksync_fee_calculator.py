from zksync2.core.utils import DEPOSIT_GAS_PER_PUBDATA_LIMIT

from src.models.order import Order
from src.services import zksync
from src.services.ethereum import get_gas_price
from src.services.fee_calculators.fee_calculator import FeeCalculator


class ZksyncFeeCalculator(FeeCalculator):

    def estimate_claim_payment_fee(self) -> int:
        """
        Due to the deposit does not exist on ethereum at this point,
        we cannot estimate the gas fee of the claim payment transaction
        So we will use fixed values for the gas
        """
        eth_claim_payment_gas = 143_785 # TODO this is a fixed value, if the contract changes, this should be updated
        return eth_claim_payment_gas * get_gas_price()

    async def estimate_message_fee(self, order: Order) -> int:
        """
        This fee is used as value in claim payment tx to ethereum
        """
        l2_gas_limit = await self.estimate_gas_limit(order)
        gas_price = get_gas_price()
        return await zksync.estimate_message_fee(gas_price, l2_gas_limit)
    
    async def estimate_gas_limit(self, order: Order) -> int:
        return await zksync.estimate_gas_limit(order.recipient_address)

    def estimate_gas_per_pub_data_byte_limit(self, order: Order) -> int:
        return DEPOSIT_GAS_PER_PUBDATA_LIMIT  # This is a constant from zksync2.core.utils
