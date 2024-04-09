from zksync2.core.utils import DEPOSIT_GAS_PER_PUBDATA_LIMIT
from web3 import Web3
from zksync2.core.utils import apply_l1_to_l2_alias
from zksync2.core.utils import DEPOSIT_GAS_PER_PUBDATA_LIMIT
from zksync2.module.request_types import EIP712Meta

from models.order import Order
from services.fee_calculators.fee_calculator import FeeCalculator
from services import ethereum, zksync


class ZksyncFeeCalculator(FeeCalculator):

    # async def estimate_overall_fee(self, order: Order) -> int:
    #     return 0  # TODO: implement

    async def estimate_message_fee(self, order: Order) -> int:
        """
        This fee is used as value in claim payment tx to ethereum
        """
        l2_gas_limit = await self.estimate_gas_limit(order)
        gas_price = ethereum.get_gas_price()
        return zksync.estimate_message_fee(l2_gas_limit, gas_price)
    
    async def estimate_gas_limit(self, order: Order) -> int:
        return 300_000  # TODO: implement
        # meta = EIP712Meta(gas_per_pub_data=DEPOSIT_GAS_PER_PUBDATA_LIMIT)
        # return zk_web3.zksync.zks_estimate_gas_l1_to_l2(
        # {
        #     "from": Web3.to_checksum_address(apply_l1_to_l2_alias(constants.ETHEREUM_CONTRACT_ADDRESS)),
        #     "to": order.recipient_address,
        #     "value": 0,
        #     "eip712Meta": meta,
        # })

    

    def estimate_gas_per_pub_data_byte_limit(self, order: Order) -> int:
        return DEPOSIT_GAS_PER_PUBDATA_LIMIT  # This is a constant from zksync2.core.utils
