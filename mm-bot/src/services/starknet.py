import asyncio
import logging
from typing import Literal

from starknet_py.common import int_from_bytes
from starknet_py.hash.selector import get_selector_from_name
from starknet_py.net.account.account import Account
from starknet_py.net.client_models import Call
from starknet_py.net.models.chains import StarknetChainId
from starknet_py.net.signer.stark_curve_signer import KeyPair

from config import constants
from services import ethereum
from services.decorators.use_fallback import use_fallback, use_async_fallback
from services.mm_full_node_client import MmFullNodeClient

SN_CHAIN_ID = int_from_bytes(constants.SN_CHAIN_ID.encode("utf-8"))
SET_ORDER_EVENT_KEY = 0x2c75a60b5bdad73ebbf539cc807fccd09875c3cbf3f44041f852cdb96d8acd3


class StarknetRpcNode:
    def __init__(self, rpc_url, private_key, wallet_address, contract_address, chain_id):
        self.full_node_client = MmFullNodeClient(node_url=rpc_url)
        key_pair = KeyPair.from_private_key(key=private_key)
        self.account = Account(
            client=self.full_node_client,
            address=wallet_address,
            key_pair=key_pair,
            chain=chain_id,  # ignore this warning TODO change to StarknetChainId when starknet_py adds sepolia
        )
        self.contract_address = contract_address


main_rpc_node = StarknetRpcNode(constants.SN_RPC_URL,
                                constants.SN_PRIVATE_KEY,
                                constants.SN_WALLET_ADDR,
                                constants.SN_CONTRACT_ADDR,
                                SN_CHAIN_ID)
fallback_rpc_node = StarknetRpcNode(constants.SN_FALLBACK_RPC_URL,
                                    constants.SN_PRIVATE_KEY,
                                    constants.SN_WALLET_ADDR,
                                    constants.SN_CONTRACT_ADDR,
                                    SN_CHAIN_ID)
rpc_nodes = [main_rpc_node, fallback_rpc_node]

logger = logging.getLogger(__name__)


class SetOrderEvent:
    def __init__(self, order_id, starknet_tx_hash, recipient_address, amount, fee, block_number, is_used=False):
        self.order_id = order_id
        self.starknet_tx_hash = starknet_tx_hash
        self.recipient_address = recipient_address
        self.amount = amount
        self.fee = fee
        self.block_number = block_number
        self.is_used = is_used

    def __str__(self):
        return f"order_id:{self.order_id}, recipient: {self.recipient_address}, amount: {self.amount}, fee: {self.fee}"


@use_async_fallback(rpc_nodes, logger, "Failed to get events")
async def get_starknet_events(from_block_number: Literal["pending", "latest"] | int | None = "pending",
                              to_block_number: Literal["pending", "latest"] | int | None = "pending",
                              continuation_token=None, rpc_node=main_rpc_node):
    events_response = await rpc_node.full_node_client.get_events(
        address=constants.SN_CONTRACT_ADDR,
        chunk_size=1000,
        keys=[[SET_ORDER_EVENT_KEY]],
        from_block_number=from_block_number,
        to_block_number=to_block_number,
        continuation_token=continuation_token
    )
    return events_response


@use_async_fallback(rpc_nodes, logger, "Failed to set order")
async def get_is_used_order(order_id, rpc_node=main_rpc_node) -> bool:
    call = Call(
        to_addr=constants.SN_CONTRACT_ADDR,
        selector=get_selector_from_name("get_order_used"),
        calldata=[order_id, 0],
    )
    status = await rpc_node.account.client.call_contract(call)
    return status[0]


async def get_order_events(from_block_number, to_block_number) -> list[SetOrderEvent]:
    continuation_token = None
    events = []
    order_events = []
    tasks = []
    while True:
        events_response = await get_starknet_events(from_block_number, to_block_number, continuation_token)
        events.extend(events_response.events)
        continuation_token = events_response.continuation_token
        if continuation_token is None:
            break

    for event in events:
        tasks.append(asyncio.create_task(create_set_order_event(event)))

    for task in tasks:
        order = await task
        order_events.append(order)
    return order_events


async def create_set_order_event(event):
    order_id = get_order_id(event)
    recipient_address = get_recipient_address(event)
    amount = get_amount(event)
    is_used = await asyncio.to_thread(ethereum.get_is_used_order, order_id, recipient_address, amount)
    fee = get_fee(event)
    return SetOrderEvent(
        order_id=order_id,
        starknet_tx_hash=event.starknet_tx_hash,
        recipient_address=recipient_address,
        amount=amount,
        fee=fee,
        block_number=event.block_number,
        is_used=is_used
    )


def get_order_id(event) -> int:
    return parse_u256_from_double_u128(event.data[0], event.data[1])


def get_recipient_address(event) -> str:
    return hex(event.data[2])


def get_amount(event) -> int:
    return parse_u256_from_double_u128(event.data[3], event.data[4])


def parse_u256_from_double_u128(low, high) -> int:
    return high << 128 | low


def get_fee(event) -> int:
    return parse_u256_from_double_u128(event.data[5], event.data[6])


@use_async_fallback(rpc_nodes, logger, "Failed to get latest block")
async def get_latest_block(rpc_node=main_rpc_node) -> int:
    latest_block = await rpc_node.full_node_client.get_block("latest")
    return latest_block.block_number


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
        transaction = await sign_invoke_transaction(call, max_fee=10000000000000)  # TODO manage fee better
        result = await send_transaction(transaction)
        await wait_for_tx(result.transaction_hash)

        logger.info(f"[+] Withdrawn from starknet: {hex(result.transaction_hash)}")
        return True
    except Exception as e:
        logger.error(f"[-] Failed to withdraw from starknet: {e}")
    return False


@use_async_fallback(rpc_nodes, logger, "Failed to sign invoke transaction")
async def sign_invoke_transaction(call: Call, max_fee: int, rpc_node=main_rpc_node):
    return await rpc_node.account.sign_invoke_v1_transaction(call, max_fee=max_fee)  # TODO migrate to V3


@use_async_fallback(rpc_nodes, logger, "Failed to estimate message fee")
async def estimate_message_fee(from_address, to_address, entry_point_selector, payload, rpc_node=main_rpc_node):
    fee = await rpc_node.full_node_client.estimate_message_fee(from_address, to_address, entry_point_selector, payload)
    return fee.overall_fee


@use_async_fallback(rpc_nodes, logger, "Failed to send transaction")
async def send_transaction(transaction, rpc_node=main_rpc_node):
    return await rpc_node.account.client.send_transaction(transaction)


@use_async_fallback(rpc_nodes, logger, "Failed to wait for tx")
async def wait_for_tx(transaction_hash, rpc_node=main_rpc_node):
    await rpc_node.account.client.wait_for_tx(transaction_hash)

