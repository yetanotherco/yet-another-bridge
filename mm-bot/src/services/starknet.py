import logging

from starknet_py.hash.selector import get_selector_from_name
from starknet_py.net.account.account import Account
from starknet_py.net.client_models import Call
from starknet_py.net.full_node_client import FullNodeClient
from starknet_py.net.models.chains import StarknetChainId
from starknet_py.net.signer.stark_curve_signer import KeyPair

from config import constants

SET_ORDER_EVENT_KEY = 0x2c75a60b5bdad73ebbf539cc807fccd09875c3cbf3f44041f852cdb96d8acd3

main_full_node_client = FullNodeClient(node_url=constants.SN_RPC_URL)
fallback_full_node_client = FullNodeClient(node_url=constants.SN_FALLBACK_RPC_URL)
full_node_clients = [main_full_node_client, fallback_full_node_client]

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
accounts = [main_account, fallback_account]

logger = logging.getLogger(__name__)


class SetOrderEvent:
    def __init__(self, order_id, recipient_address, amount):
        self.order_id = order_id
        self.recipient_address = recipient_address
        self.amount = amount

    def __str__(self):
        return f"order_id:{self.order_id}, recipient: {self.recipient_address}, amount: {self.amount}"


async def get_starknet_events():
    for client in full_node_clients:
        try:
            events_response = await client.get_events(
                address=constants.SN_CONTRACT_ADDR,
                chunk_size=10,
                keys=[[SET_ORDER_EVENT_KEY]],
                from_block_number='pending'
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


async def get_latest_unfulfilled_orders() -> set[SetOrderEvent]:
    request_result = await get_starknet_events()
    if request_result is None:
        return set()

    events = request_result.events
    orders = set()
    for event in events:
        is_used = await get_is_used_order(event.data[0])
        if not is_used:
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
