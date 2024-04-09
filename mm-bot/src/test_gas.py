import asyncio
import json
import logging
import os
from web3 import Web3

import zksync2
from zksync2.module.module_builder import ZkSyncBuilder
from zksync2.core.utils import apply_l1_to_l2_alias
# from zksync2.module.zksync_module import zks_estimate_gas_l1_to_l2
from zksync2.core.utils import DEPOSIT_GAS_PER_PUBDATA_LIMIT
from zksync2.module.request_types import EIP712Meta
from config import constants
from config.database_config import get_db
from config.logging_config import setup_logger
from models.network import Network
from models.order import Order
from persistence.error_dao import ErrorDao
from persistence.order_dao import OrderDao
from services.order_service import OrderService
from zksync2.account.wallet import Wallet

from eth_account import Account
from eth_account.signers.local import LocalAccount
from services.ethereum import claim_payment_zksync
from services import ethereum

setup_logger()
logger = logging.getLogger(__name__)

abi_file = json.load(open(os.getcwd() + '/abi/Escrow.json'))['abi']
zk_web3 = ZkSyncBuilder.build(constants.ZKSYNC_RPC)
eth_web3 = Web3(Web3.HTTPProvider(constants.ETHEREUM_RPC))

contract = zk_web3.zksync.contract(address=constants.ZKSYNC_CONTRACT_ADDRESS, abi=abi_file)
account: LocalAccount = Account.from_key(constants.ETHEREUM_PRIVATE_KEY)
wallet = Wallet(zk_web3, eth_web3, account)

async def run():
    logger.info("Starting claim bot")
    order_dao = OrderDao(get_db())
    error_dao = ErrorDao(get_db())
    order_service = OrderService(order_dao, error_dao)

    order: Order = order_service.get_order(3, Network.ZKSYNC)
    print(ethereum.get_is_used_order(order.order_id, order.recipient_address, order.get_int_amount(), Network.ZKSYNC.value))
    chain_id = zk_web3.eth.chain_id
    logger.info(f"Chain id: {chain_id}")
    gas_price = zk_web3.zksync.gas_price
    logger.info(f"Gas price L2: {gas_price}")

    order_id = Web3.to_int(order.order_id)
    recipient_address = order.recipient_address
    amount = Web3.to_int(order.get_int_amount())
    print(f"Order id: {order_id}")
    print(f"Recipient address: {recipient_address}")
    print(f"Amount: {amount}")

    meta = EIP712Meta(gas_per_pub_data=DEPOSIT_GAS_PER_PUBDATA_LIMIT)

    # tx = contract.functions.claim_payment(order_id, recipient_address, amount).build_transaction({
    #     "from": Web3.to_checksum_address(apply_l1_to_l2_alias(constants.ETHEREUM_CONTRACT_ADDRESS)),
    #     "value": 0,
    #     "maxPriorityFeePerGas": 1_000,
    #     "maxFeePerGas": hex(gas_price),
    # })

    # l2_gas_limit = zk_web3.zksync.zks_estimate_gas_l1_to_l2(tx)
    # logger.info(f"Gas: {gas}")

    l2_gas_limit = zk_web3.zksync.zks_estimate_gas_l1_to_l2(
        {
            "from": Web3.to_checksum_address(apply_l1_to_l2_alias(constants.ETHEREUM_CONTRACT_ADDRESS)),
            "to": order.recipient_address,
            "value": 0,
            "eip712Meta": meta,
        }
    )
    logger.info(f"Estimate gas: {l2_gas_limit}")

    base_cost = wallet.get_base_cost(gas_price=ethereum.get_gas_price(), l2_gas_limit=l2_gas_limit)
    print(f"Base cost: {base_cost}")


    # tx = contract.functions.claim_payment(order_id, recipient_address, amount).build_transaction({
    #     "from": Web3.to_checksum_address(apply_l1_to_l2_alias(constants.ETHEREUM_CONTRACT_ADDRESS)),
    #     # "nonce": get_nonce(rpc_node.w3, rpc_node.account.address),
    #     "value": 0,
    #     # "maxPriorityFeePerGas": 1_000_000,
    #     "maxFeePerGas": hex(gas_price),
    # })
    # print(f"Tx: {tx}")

    # call_data = tx.enc
    # l1_tx_receipt = wallet.request_execute(RequestExecuteCallMsg(
    #     contract_address=Web3.to_checksum_address(zk_web3.zksync.main_contract_address),
    #     call_data=,
    #     l2_value=amount,
    #     l2_gas_limit=l2_gas_limit))

    # l2_hash = zk_web3.zksync.get_l2_hash_from_priority_op(l1_tx_receipt, wallet.main_contract)
    # zk_web3.zksync.wait_for_transaction_receipt(l2_hash)

    tx_hash = claim_payment_zksync(order_id, recipient_address, amount, base_cost, l2_gas_limit, DEPOSIT_GAS_PER_PUBDATA_LIMIT)
    logger.info(f"Tx hash: {tx_hash.hex()}")
    # Wait for tx
    ethereum.wait_for_transaction_receipt(tx_hash)



    

asyncio.run(run())