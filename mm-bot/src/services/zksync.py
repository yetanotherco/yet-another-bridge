import asyncio
import json
import logging
import os
from typing import cast

from web3 import AsyncWeb3
from web3.eth.async_eth import AsyncContract
from web3.types import EventData
from hexbytes import HexBytes


from config import constants
from models.set_order_event import SetOrderEvent
from models.zksync_log import ZksyncLog
from services.decorators.use_fallback import use_async_fallback

# Just for keep consistency with the ethereum and starknet
# services it won't be a class. It will be a set of functions

escrow_abi_file = json.load(open(os.getcwd() + '/abi/Escrow.json'))['abi']


class EthereumAsyncRpcNode:
    """
    This implementation use async calls to the Ethereum RPC
    Using async methods it's not necessary to create a thread for avoid blocking
    TODO migrate Ethereum service to async calls
    https://stackoverflow.com/questions/68954638/how-to-use-asynchttpprovider-in-web3py
    """

    def __init__(self, rpc_url, private_key, contract_address, abi):
        self.w3 = AsyncWeb3(AsyncWeb3.AsyncHTTPProvider(rpc_url))
        # self.account = self.w3.eth.account.from_key(private_key)  # TODO use private key when necessary
        self.contract: AsyncContract = self.w3.eth.contract(address=contract_address, abi=abi)


main_rpc_node = EthereumAsyncRpcNode(constants.ZKSYNC_RPC,
                                     None,
                                     constants.ZKSYNC_CONTRACT_ADDRESS,
                                     escrow_abi_file)
fallback_rpc_node = EthereumAsyncRpcNode(constants.ZKSYNC_FALLBACK_RPC,
                                         None,
                                         constants.ZKSYNC_CONTRACT_ADDRESS,
                                         escrow_abi_file)
rpc_nodes = [main_rpc_node, fallback_rpc_node]

logger = logging.getLogger(__name__)


# TODO if we migrate to classes it can be inherited from Ethereum service
@use_async_fallback(rpc_nodes, logger, "Failed to get latest block")
async def get_latest_block(rpc_node=main_rpc_node) -> int:
    return await rpc_node.w3.eth.block_number


@use_async_fallback(rpc_nodes, logger, "Failed to get set_order events from ZkSync")
async def get_set_order_logs(from_block_number: int, to_block_number: int, rpc_node=main_rpc_node) -> list[EventData]:
    logs = await rpc_node.contract.events.SetOrder().get_logs(
        fromBlock=hex(from_block_number),
        toBlock=hex(to_block_number)
    )
    return logs


async def get_set_order_events(from_block, to_block) -> list[SetOrderEvent]:
    """
    Get set_orders events from the escrow
    """
    set_order_logs: list[EventData] = await get_set_order_logs(from_block, to_block)
    tasks = []

    # Create a list of tasks to parallelize the creation of the SetOrderEvent list
    for log in set_order_logs:
        transaction = await get_tx(log['transactionHash'])
        from_address = transaction['from']
        zksync_log = ZksyncLog(**log, from_address=from_address)
        tasks.append(asyncio.create_task(SetOrderEvent.from_zksync(zksync_log)))

    set_order_events = await asyncio.gather(*tasks)
    return cast(list[SetOrderEvent], set_order_events)


@use_async_fallback(rpc_nodes, logger, "Failed to get the tx")
async def get_tx(tx_hash: HexBytes, rpc_node=main_rpc_node):
    return await rpc_node.w3.eth.get_transaction(tx_hash)
