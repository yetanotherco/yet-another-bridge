from zksync2.core.utils import DEPOSIT_GAS_PER_PUBDATA_LIMIT
from web3 import Web3
from zksync2.core.utils import apply_l1_to_l2_alias
from zksync2.core.utils import DEPOSIT_GAS_PER_PUBDATA_LIMIT
from zksync2.module.request_types import EIP712Meta

from models.order import Order
from services.fee_calculators.fee_calculator import FeeCalculator
from services import ethereum, zksync


class ZksyncFeeCalculator(FeeCalculator):
    async def estimate_message_fee(self, order: Order) -> int:
        """
        This fee is used as value in claim payment tx to ethereum
        """
        l2_gas_limit = await self.estimate_gas_limit(order)
        gas_price = ethereum.get_gas_price()
        return await zksync.estimate_message_fee(gas_price, l2_gas_limit)
    
    async def estimate_gas_limit(self, order: Order) -> int:
        return await zksync.estimate_gas_limit(order.recipient_address)

    def estimate_gas_per_pub_data_byte_limit(self, order: Order) -> int:
        return DEPOSIT_GAS_PER_PUBDATA_LIMIT  # This is a constant from zksync2.core.utils
