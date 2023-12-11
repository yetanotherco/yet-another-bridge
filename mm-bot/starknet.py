import logging
import requests
import constants
import json
import os

from starknet_py.contract import Contract
from starknet_py.net.full_node_client import FullNodeClient
from starknet_py.net.account.account import Account
from starknet_py.net.models.chains import StarknetChainId
from starknet_py.net.signer.stark_curve_signer import KeyPair
from starknet_py.hash.selector import get_selector_from_name
from starknet_py.net.client_models import Call
from starknet_py.cairo.felt import decode_shortstring

SET_ORDER_EVENT_KEY = 0x2c75a60b5bdad73ebbf539cc807fccd09875c3cbf3f44041f852cdb96d8acd3

full_node_client = FullNodeClient(node_url=constants.SN_RPC_URL)

key_pair = KeyPair.from_private_key(key=constants.SN_PRIVATE_KEY)
account = Account(
    client=full_node_client,
    address=constants.SN_WALLET_ADDR,
    key_pair=key_pair,
    chain=StarknetChainId.TESTNET,
)

logger = logging.getLogger(__name__)


class SetOrderEvent:
    def __init__(self, order_id, recipient_address, amount):
        self.order_id = order_id
        self.recipient_address = recipient_address
        self.amount = amount

    def __str__(self):
        return f"order_id:{self.order_id}, recipent: {self.recipient_address}, amount: {self.amount}"


async def get_starknet_events() -> int:
    events_response = await full_node_client.get_events(
        address=constants.SN_CONTRACT_ADDR,
        chunk_size=10,
        keys=[[SET_ORDER_EVENT_KEY]],
        from_block_number='pending'
    )

    return events_response


async def get_is_used_order(order_id) -> bool:
    call = Call(
        to_addr=constants.SN_CONTRACT_ADDR,
        selector=get_selector_from_name("get_order_used"),
        calldata=[order_id, 0],
    )
    try:
        status = await account.client.call_contract(call)
        return status[0]
    except Exception as e:
        return True


async def get_latest_unfulfilled_orders():
    request_result = await get_starknet_events()
    events = request_result.events

    orders = set()
    for event in events:
        status = await get_is_used_order(event.data[0])
        if not status:
            order = SetOrderEvent(
                order_id=event.data[0],
                recipient_address=hex(event.data[2]),
                amount=event.data[3],
            )
            orders.add(order)
    return orders


async def withdraw(order_id, block, slot) -> bool:
    slot = slot.hex()
    slot_high = int(slot.replace("0x", "")[0:32], 16)
    slot_low = int(slot.replace("0x", "")[32:64], 16)
    call = Call(
        to_addr=int(constants.SN_CONTRACT_ADDR, 0),
        selector=get_selector_from_name("withdraw"),
        calldata=[order_id, 0, block, 0, slot_low, slot_high]
    )
    try:
        transaction = await account.sign_invoke_transaction(call, max_fee=10000000000000)
        result = await account.client.send_transaction(transaction)
        await account.client.wait_for_tx(result.transaction_hash)

        logger.info(f"[+] Withdrawn from starknet: {hex(result.transaction_hash)}")
    except Exception as e:
        logger.error(f"[-] Failed to withdraw from starknet: {e}")
