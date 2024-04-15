import asyncio
import json
import logging
import os
from typing import cast

from web3 import AsyncWeb3
from web3.eth.async_eth import AsyncContract
from web3.types import EventData

from config import constants
from models.set_order_event import SetOrderEvent
from services.decorators.use_fallback import use_async_fallback
from services.ethereum import main_rpc_node as ethereum_main_rpc_node, fallback_rpc_node as ethereum_fallback_rpc_node

from zksync2.account.wallet import Wallet
from zksync2.core.utils import DEPOSIT_GAS_PER_PUBDATA_LIMIT, apply_l1_to_l2_alias
from zksync2.module.request_types import EIP712Meta
from zksync2.module.module_builder import ZkSyncBuilder

from web3 import Web3


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

    def __init__(self, rpc_url, private_key, contract_address, ethereum_rpc_node, abi):
        self.w3 = AsyncWeb3(AsyncWeb3.AsyncHTTPProvider(rpc_url))
        self.account = self.w3.eth.account.from_key(private_key)
        self.contract: AsyncContract = self.w3.eth.contract(address=contract_address, abi=abi)
        
        # TODO: create ZKSyncAsyncRpcNode that extends EthereumAsyncRpcNode and adds zksync and wallet
        zk_w3 = ZkSyncBuilder.build(constants.ZKSYNC_RPC)
        self.zksync = zk_w3.zksync
        self.wallet = Wallet(zk_w3, ethereum_rpc_node.w3, self.account)


main_rpc_node = EthereumAsyncRpcNode(constants.ZKSYNC_RPC,
                                     constants.ETHEREUM_PRIVATE_KEY,
                                     constants.ZKSYNC_CONTRACT_ADDRESS,
                                     ethereum_main_rpc_node,
                                     escrow_abi_file)
fallback_rpc_node = EthereumAsyncRpcNode(constants.ZKSYNC_FALLBACK_RPC,
                                         constants.ETHEREUM_PRIVATE_KEY,
                                         constants.ZKSYNC_CONTRACT_ADDRESS,
                                         ethereum_fallback_rpc_node,
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


@use_async_fallback(rpc_nodes, logger, "Failed to estimate message fee")
async def estimate_message_fee(gas_price, l2_gas_limit, rpc_node=main_rpc_node):
    return await asyncio.to_thread(rpc_node.wallet.get_base_cost, gas_price=gas_price, l2_gas_limit=l2_gas_limit)


@use_async_fallback(rpc_nodes, logger, "Failed to estimate message fee")
async def estimate_gas_limit(recipient, rpc_node=main_rpc_node):
    meta = EIP712Meta(gas_per_pub_data=DEPOSIT_GAS_PER_PUBDATA_LIMIT)
    return await asyncio.to_thread(rpc_node.zksync.zks_estimate_gas_l1_to_l2, transaction={
        "from": Web3.to_checksum_address(apply_l1_to_l2_alias(constants.ETHEREUM_CONTRACT_ADDRESS)),
        "to": recipient,
        "value": 0,
        "eip712Meta": meta,
    })

async def get_set_order_events(from_block, to_block) -> list[SetOrderEvent]:
    """
    Get set_orders events from the escrow
    """
    set_order_logs: list[EventData] = await get_set_order_logs(from_block, to_block)
    # Create a list of tasks to parallelize the creation of the SetOrderEvent list
    tasks = [asyncio.create_task(SetOrderEvent.from_zksync(log)) for log in set_order_logs]
    set_order_events = await asyncio.gather(*tasks)
    return cast(list[SetOrderEvent], set_order_events)
