import asyncio

from web3 import Web3

from models.order import Order
from services.ethereum import create_transfer, estimate_transaction_fee, get_gas_price
from services.withdrawer.ethereum_withdrawer import EthereumWithdrawer


async def estimate_overall_fee(order: Order) -> int:
    """
    Operational cost per order done by the market maker.
    This includes:
        calling the transfer (from YABTransfer) +
        withdraw (from YABTransfer) +
        msg fee paid to Starknet (when calling withdraw)
    """
    transfer_fee = await asyncio.to_thread(estimate_transfer_fee, order)
    message_fee = await estimate_message_fee(order)
    withdraw_fee = estimate_yab_withdraw_fee()
    return transfer_fee + message_fee + withdraw_fee


def estimate_transfer_fee(order: Order) -> int:
    dst_addr_bytes = int(order.recipient_address, 0)
    deposit_id = Web3.to_int(order.order_id)
    amount = Web3.to_int(order.get_int_amount())

    unsent_tx, signed_tx = create_transfer(deposit_id, dst_addr_bytes, amount)

    return estimate_transaction_fee(unsent_tx)


def estimate_yab_withdraw_fee() -> int:
    """
    Due to the deposit does not exist on ethereum at this point,
    we cannot estimate the gas fee of the withdrawal transaction
    So we will use fixed values for the gas
    """
    eth_withdrawal = 86139
    return eth_withdrawal * get_gas_price()


async def estimate_message_fee(order: Order) -> int:
    return await EthereumWithdrawer.estimate_withdraw_fallback_message_fee(order.order_id,
                                                                           order.recipient_address,
                                                                           order.get_int_amount())
