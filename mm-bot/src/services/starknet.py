import asyncio
import logging
from typing import Literal, cast

from starknet_py.common import int_from_bytes
from starknet_py.hash.selector import get_selector_from_name
from starknet_py.net.account.account import Account
from starknet_py.net.client_models import Call, InvokeTransaction
from starknet_py.net.models.chains import StarknetChainId
from starknet_py.net.signer.stark_curve_signer import KeyPair

from src.config import constants
from src.models.set_order_event import SetOrderEvent
from src.services.decorators.use_fallback import use_async_fallback
from src.services.mm_full_node_client import MmFullNodeClient

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


main_rpc_node = StarknetRpcNode(constants.STARKNET_RPC,
                                constants.STARKNET_PRIVATE_KEY,
                                constants.STARKNET_WALLET_ADDRESS,
                                constants.STARKNET_CONTRACT_ADDRESS,
                                constants.STARKNET_CHAIN_ID)
fallback_rpc_node = StarknetRpcNode(constants.STARKNET_FALLBACK_RPC,
                                    constants.STARKNET_PRIVATE_KEY,
                                    constants.STARKNET_WALLET_ADDRESS,
                                    constants.STARKNET_CONTRACT_ADDRESS,
                                    constants.STARKNET_CHAIN_ID)
rpc_nodes = [main_rpc_node, fallback_rpc_node]

logger = logging.getLogger(__name__)


@use_async_fallback(rpc_nodes, logger, "Failed to get events")
async def get_starknet_events(from_block_number: Literal["pending", "latest"] | int | None = "pending",
                              to_block_number: Literal["pending", "latest"] | int | None = "pending",
                              continuation_token=None, rpc_node=main_rpc_node):
    events_response = await rpc_node.full_node_client.get_events(
        address=constants.STARKNET_CONTRACT_ADDRESS,
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
        to_addr=constants.STARKNET_CONTRACT_ADDRESS,
        selector=get_selector_from_name("get_order_used"),
        calldata=[order_id, 0],
    )
    status = await rpc_node.account.client.call_contract(call)
    return status[0]


async def get_order_events(from_block_number, to_block_number) -> list[SetOrderEvent]:
    continuation_token = None
    events = []
    event_tasks = []
    order_events = []
    order_tasks = []
    while True:
        events_response = await get_starknet_events(from_block_number, to_block_number, continuation_token)
        events.extend(events_response.events)
        continuation_token = events_response.continuation_token
        if continuation_token is None:
            break

    for event in events:
        event_tasks.append(asyncio.create_task(get_transaction(event.tx_hash)))

    transactions = await asyncio.gather(*event_tasks)

    # asyncio.gather() returns the results in the same order as the input list, so we can zip the two lists
    # https://docs.python.org/3/library/asyncio-task.html#running-tasks-concurrently
    for event, transaction in zip(events, transactions):
        transaction = cast(InvokeTransaction, transaction)
        event.from_address = f'0x{transaction.sender_address:064x}'
        order_tasks.append(asyncio.create_task(SetOrderEvent.from_starknet(event)))

    order_events = await asyncio.gather(*order_tasks)

    return cast(list[SetOrderEvent], order_events)


@use_async_fallback(rpc_nodes, logger, "Failed to get latest block number")
async def get_latest_block(rpc_node=main_rpc_node) -> int:
    return await rpc_node.full_node_client.get_block_number()


async def claim_payment(order_id, block, slot) -> bool:
    slot = slot.hex()
    slot_high = int(slot.replace("0x", "")[0:32], 16)
    slot_low = int(slot.replace("0x", "")[32:64], 16)
    call = Call(
        to_addr=int(constants.STARKNET_CONTRACT_ADDRESS, 0),
        selector=get_selector_from_name("claim_payment"),
        calldata=[order_id, 0, block, 0, slot_low, slot_high]
    )
    try:
        transaction = await sign_invoke_transaction(call, max_fee=10000000000000)  # TODO manage fee better
        result = await send_transaction(transaction)
        await wait_for_tx(result.transaction_hash)

        logger.info(f"[+] Claim payment from starknet: {hex(result.transaction_hash)}")
        return True
    except Exception as e:
        logger.error(f"[-] Failed to claim payment from starknet: {e}")
    return False


@use_async_fallback(rpc_nodes, logger, "Failed to sign invoke transaction")
async def sign_invoke_transaction(call: Call, max_fee: int, rpc_node=main_rpc_node):
    return await rpc_node.account.sign_invoke_v1_transaction(call, max_fee=max_fee)  # TODO migrate to V3


@use_async_fallback(rpc_nodes, logger, "Failed to estimate message fee")
async def estimate_message_fee(from_address, to_address, entry_point_selector, payload, rpc_node=main_rpc_node):
    fee = await rpc_node.full_node_client.estimate_message_fee(from_address, to_address, entry_point_selector, payload)
    return int(fee.overall_fee / 100)


@use_async_fallback(rpc_nodes, logger, "Failed to send transaction")
async def send_transaction(transaction, rpc_node=main_rpc_node):
    return await rpc_node.account.client.send_transaction(transaction)


@use_async_fallback(rpc_nodes, logger, "Failed to wait for tx")
async def wait_for_tx(transaction_hash, rpc_node=main_rpc_node):
    await rpc_node.account.client.wait_for_tx(transaction_hash)


@use_async_fallback(rpc_nodes, logger, "Failed to get the tx")
async def get_transaction(transaction_hash, rpc_node=main_rpc_node):
    return await rpc_node.account.client.get_transaction(transaction_hash)
