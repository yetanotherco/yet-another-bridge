from models.order import Order
from services.fee_calculators.fee_calculator import FeeCalculator


class ZksyncFeeCalculator(FeeCalculator):

    async def estimate_overall_fee(self, order: Order) -> int:
        return 0  # TODO: implement

    async def estimate_message_fee(self, order: Order) -> int:
        return 0  # TODO: implement
