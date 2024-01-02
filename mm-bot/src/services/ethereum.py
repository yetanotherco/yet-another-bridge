import logging
import json
import os
from web3 import Web3

from config import constants

main_w3 = Web3(Web3.HTTPProvider(constants.ETH_RPC_URL))
fallback_w3 = Web3(Web3.HTTPProvider(constants.ETH_FALLBACK_RPC_URL))
w3_clients = [main_w3, fallback_w3]

main_account = main_w3.eth.account.from_key(constants.ETH_PRIVATE_KEY)
fallback_account = fallback_w3.eth.account.from_key(constants.ETH_PRIVATE_KEY)
accounts = [main_account, fallback_account]

# get only the abi not the entire file
abi = json.load(open(os.getcwd() + '/abi/YABTransfer.json'))['abi']
"""
contracts_rpc are instances from the same contract but from different nodes
So if a node is down we can use the other one
"""
main_contract_rpc = main_w3.eth.contract(address=constants.ETH_CONTRACT_ADDR, abi=abi)
fallback_contract_rpc = fallback_w3.eth.contract(address=constants.ETH_CONTRACT_ADDR, abi=abi)
contracts_rpc = [main_contract_rpc, fallback_contract_rpc]

logger = logging.getLogger(__name__)


def get_latest_block() -> int:
    for w3 in w3_clients:
        try:
            return w3.eth.block_number
        except Exception as exception:
            logger.warning(f"[-] Failed to get block number from node: {exception}")
    logger.error(f"[-] Failed to get block number from all nodes")


def get_is_used_order(order_id, recipient_address, amount) -> bool:
    is_used_index = 2
    order_data = Web3.solidity_keccak(['uint256', 'uint256', 'uint256'],
                                      [order_id, int(recipient_address, 0), amount])
    for contract_rpc in contracts_rpc:
        try:
            res = contract_rpc.functions.transfers(order_data).call()
            return res[is_used_index]
        except Exception as exception:
            logger.warning(f"[-] Failed to get is used order from node: {exception}")
    logger.error(f"[-] Failed to get is used order from all nodes")
    raise Exception("Failed to get is used order from all nodes")


def get_balance() -> int:
    for w3 in w3_clients:
        try:
            return w3.eth.get_balance(main_account.address)
        except Exception as exception:
            logger.warning(f"[-] Failed to get balance from node: {exception}")
    logger.error(f"[-] Failed to get balance from all nodes")
    raise Exception("Failed to get balance from all nodes")


def has_funds(amount: int) -> bool:
    return get_balance() >= amount


def transfer(deposit_id, dst_addr, amount):
    dst_addr_bytes = int(dst_addr, 0)
    deposit_id = Web3.to_int(deposit_id)
    amount = Web3.to_int(amount)

    signed_tx = create_transfer(deposit_id, dst_addr_bytes, amount)

    tx_hash = send_raw_transaction(signed_tx)
    return tx_hash


# we need amount so the transaction is valid with the transfer that will be transferred
def create_transfer(deposit_id, dst_addr_bytes, amount):
    for index, w3 in enumerate(w3_clients):
        try:
            unsent_tx = contracts_rpc[index].functions.transfer(deposit_id, dst_addr_bytes, amount).build_transaction({
                "chainId": 5,
                "from": accounts[index].address,
                "nonce": get_nonce(w3, accounts[index].address),
                "value": amount,
            })
            signed_tx = w3.eth.account.sign_transaction(unsent_tx, private_key=accounts[index].key)
            return signed_tx
        except Exception as exception:
            logger.warning(f"[-] Failed to create transfer eth on node: {exception}")
    logger.error(f"[-] Failed to create transfer eth on all nodes")
    raise Exception("Failed to create transfer eth on all nodes")


def withdraw(deposit_id, dst_addr, amount):
    deposit_id = Web3.to_int(deposit_id)
    dst_addr_bytes = int(dst_addr, 0)
    amount = Web3.to_int(amount)

    signed_tx = create_withdraw(deposit_id, dst_addr_bytes, amount)

    tx_hash = send_raw_transaction(signed_tx)
    return tx_hash


def create_withdraw(deposit_id, dst_addr_bytes, amount):
    for index, w3 in enumerate(w3_clients):
        try:
            unsent_tx = contracts_rpc[index].functions.withdraw(deposit_id, dst_addr_bytes, amount).build_transaction({
                "chainId": 5,
                "from": accounts[index].address,
                "nonce": get_nonce(w3, accounts[index].address),
                "value": amount,
            })
            signed_tx = w3.eth.account.sign_transaction(unsent_tx, private_key=accounts[index].key)
            return signed_tx
        except Exception as exception:
            logger.warning(f"[-] Failed to create withdraw eth on node: {exception}")
    logger.error(f"[-] Failed to create withdraw eth on all nodes")
    raise Exception("Failed to create withdraw eth on all nodes")


def get_nonce(w3: Web3, address):
    return w3.eth.get_transaction_count(address)


def send_raw_transaction(signed_tx):
    for w3 in w3_clients:
        try:
            tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
            return tx_hash
        except Exception as exception:
            logger.warning(f"[-] Failed to send raw transaction on node: {exception}")
    logger.error(f"[-] Failed to send raw transaction on all nodes")
    raise Exception("Failed to send raw transaction on all nodes")


def wait_for_transaction_receipt(tx_hash):
    for w3 in w3_clients:
        try:
            w3.eth.wait_for_transaction_receipt(tx_hash)
            return True
        except Exception as exception:
            logger.warning(f"[-] Failed to wait for transaction receipt on node: {exception}")
    logger.error(f"[-] Failed to wait for transaction receipt on all nodes")
    raise Exception("Failed to wait for transaction receipt on all nodes")
