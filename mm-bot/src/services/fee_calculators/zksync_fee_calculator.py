from zksync2.core.utils import DEPOSIT_GAS_PER_PUBDATA_LIMIT

from models.order import Order
from services.fee_calculators.fee_calculator import FeeCalculator


class ZksyncFeeCalculator(FeeCalculator):

    async def estimate_overall_fee(self, order: Order) -> int:
        return 0  # TODO: implement

    async def estimate_message_fee(self, order: Order) -> int:
        """
        This fee is used as value in claim payment tx to ethereum
        """
        return 10_000_000_000_000_000  # 0.01 ETH TODO implement estimation

    async def estimate_gas_limit(self, order: Order) -> int:
        return 300_000

    def estimate_gas_per_pub_data_byte_limit(self, order: Order) -> int:
        return DEPOSIT_GAS_PER_PUBDATA_LIMIT  # This is a constant from zksync2.core.utils
