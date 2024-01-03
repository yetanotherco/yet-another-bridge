import asyncio
import logging
from typing import Literal

from starknet_py.hash.selector import get_selector_from_name
from starknet_py.net.account.account import Account
from starknet_py.net.client_models import Call
from starknet_py.net.models.chains import StarknetChainId
from starknet_py.net.signer.stark_curve_signer import KeyPair

from config import constants
from services import ethereum
from services.mm_full_node_client import MmFullNodeClient

SET_ORDER_EVENT_KEY = 0x2c75a60b5bdad73ebbf539cc807fccd09875c3cbf3f44041f852cdb96d8acd3

main_full_node_client = MmFullNodeClient(node_url=constants.SN_RPC_URL)
fallback_full_node_client = MmFullNodeClient(node_url=constants.SN_FALLBACK_RPC_URL)
full_node_clients = [fallback_full_node_client, main_full_node_client]

key_pair = KeyPair.from_private_key(key=constants.SN_PRIVATE_KEY)
main_account = Account(
    client=main_full_node_client,
    address=constants.SN_WALLET_ADDR,
    key_pair=key_pair,
    chain=StarknetChainId.TESTNET,
)
fallback_account = Account(
    client=fallback_full_node_client,
    address=constants.SN_WALLET_ADDR,
    key_pair=key_pair,
    chain=StarknetChainId.TESTNET,
)
accounts = [fallback_account, main_account]

logger = logging.getLogger(__name__)


class SetOrderEvent:
    def __init__(self, order_id, recipient_address, amount, fee, block_number, is_used=False):
        self.order_id = order_id
        self.recipient_address = recipient_address
        self.amount = amount
        self.fee = fee
        self.block_number = block_number
        self.is_used = is_used

    def __str__(self):
        return f"order_id:{self.order_id}, recipient: {self.recipient_address}, amount: {self.amount}, fee: {self.fee}"


async def get_starknet_events(from_block_number: Literal["pending", "latest"] | int | None = "pending",
                              to_block_number: Literal["pending", "latest"] | int | None = "pending",
                              continuation_token=None):
    for client in full_node_clients:
        try:
            events_response = await client.get_events(
                address=constants.SN_CONTRACT_ADDR,
                chunk_size=1000,
                keys=[[SET_ORDER_EVENT_KEY]],
                from_block_number=from_block_number,
                to_block_number=to_block_number,
                continuation_token=continuation_token
            )
            return events_response
        except Exception as exception:
            logger.warning(f"[-] Failed to get events from node: {exception}")
    logger.error(f"[-] Failed to get events from all nodes")
    return None


async def get_is_used_order(order_id) -> bool:
    call = Call(
        to_addr=constants.SN_CONTRACT_ADDR,
        selector=get_selector_from_name("get_order_used"),
        calldata=[order_id, 0],
    )
    for account in accounts:
        try:
            status = await account.client.call_contract(call)
            return status[0]
        except Exception as exception:
            logger.warning(f"[-] Failed to get order status from node: {exception}")
    logger.error(f"[-] Failed to get order status from all nodes")
    return True


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
    # fee_threshold = 0.0001 * event.data[3]
    # if event.data[5] < fee_threshold:
    #     logger.info(f"[-] Order {event.data[0]} has a fee too low to process ({event.data[5]} < {fee_threshold}). Skipping")
    #     return -1
    # return event.data[5]
    return 0


async def get_latest_block() -> int:
    for client in full_node_clients:
        try:
            latest_block = await client.get_block("latest")
            return latest_block.block_number
        except Exception as exception:
            logger.warning(f"[-] Failed to get latest block from node: {exception}")
    logger.error(f"[-] Failed to get latest block from all nodes")
    return 0


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


async def sign_invoke_transaction(call: Call, max_fee: int):
    for account in accounts:
        try:
            transaction = await account.sign_invoke_transaction(call, max_fee=max_fee)
            return transaction
        except Exception as e:
            logger.warning(f"[-] Failed to sign invoke transaction: {e}")
    logger.error(f"[-] Failed to sign invoke transaction from all nodes")
    raise Exception("Failed to sign invoke transaction from all nodes")


async def send_transaction(transaction):
    for account in accounts:
        try:
            result = await account.client.send_transaction(transaction)
            return result
        except Exception as e:
            logger.warning(f"[-] Failed to send transaction: {e}")
    logger.error(f"[-] Failed to send transaction from all nodes")
    raise Exception("Failed to send transaction from all nodes")


async def wait_for_tx(transaction_hash):
    for account in accounts:
        try:
            await account.client.wait_for_tx(transaction_hash)
            return
        except Exception as e:
            logger.warning(f"[-] Failed to wait for tx: {e}")
    logger.error(f"[-] Failed to wait for tx from all nodes")
    raise Exception("Failed to wait for tx from all nodes")
