import asyncio
import logging

from web3 import Web3

from models.order import Order
from services.ethereum import create_transfer, estimate_transaction_fee, get_gas_price
from services.payment_claimer.ethereum_payment_claimer import EthereumPaymentClaimer

logger = logging.getLogger(__name__)


async def estimate_overall_fee(order: Order) -> int:
    """
    Operational cost per order done by the market maker.
    This includes:
        calling the transfer (from PaymentRegistry) +
        claimPayment (from PaymentRegistry) +
        msg fee paid to Starknet (when calling claim_payment)
    """
    transfer_fee = await asyncio.to_thread(estimate_transfer_fee, order)
    message_fee = await estimate_message_fee(order)
    claim_payment_fee = estimate_claim_payment_fee()
    logger.info(f"Transfer fee: {transfer_fee}")
    logger.info(f"Message fee: {message_fee}")
    logger.info(f"Claim payment fee: {claim_payment_fee}")
    logger.info(f"Overall fee: {transfer_fee + message_fee + claim_payment_fee}")
    return transfer_fee + message_fee + claim_payment_fee


def estimate_transfer_fee(order: Order) -> int:
    dst_addr_bytes = int(order.recipient_address, 0)
    deposit_id = Web3.to_int(order.order_id)
    amount = Web3.to_int(order.get_int_amount())

    unsent_tx, signed_tx = create_transfer(deposit_id, dst_addr_bytes, amount)

    return estimate_transaction_fee(unsent_tx)


def estimate_claim_payment_fee() -> int:
    """
    Due to the deposit does not exist on ethereum at this point,
    we cannot estimate the gas fee of the claim payment transaction
    So we will use fixed values for the gas
    """
    eth_claim_payment_gas = 86139  # TODO this is a fixed value, if the contract changes, this should be updated
    return eth_claim_payment_gas * get_gas_price()


async def estimate_message_fee(order: Order) -> int:
    return await EthereumPaymentClaimer.estimate_claim_payment_fallback_message_fee(order.order_id,
                                                                                    order.recipient_address,
                                                                                    order.get_int_amount())
