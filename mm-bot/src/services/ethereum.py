import logging
import json
import os
from web3 import Web3

from config import constants
from models.network import Network
from services.decorators.use_fallback import use_fallback

ETHEREUM_CHAIN_ID = int(constants.ETHEREUM_CHAIN_ID)
# get only the abi not the entire file
abi_file = json.load(open(os.getcwd() + '/abi/PaymentRegistry.json'))['abi']


class EthereumRpcNode:
    def __init__(self, rpc_url, private_key, contract_address, abi):
        self.w3 = Web3(Web3.HTTPProvider(rpc_url))
        self.account = self.w3.eth.account.from_key(private_key)
        self.contract = self.w3.eth.contract(address=contract_address, abi=abi)


main_rpc_node = EthereumRpcNode(constants.ETHEREUM_RPC,
                                constants.ETHEREUM_PRIVATE_KEY,
                                constants.ETHEREUM_CONTRACT_ADDRESS,
                                abi_file)
fallback_rpc_node = EthereumRpcNode(constants.ETHEREUM_FALLBACK_RPC,
                                    constants.ETHEREUM_PRIVATE_KEY,
                                    constants.ETHEREUM_CONTRACT_ADDRESS,
                                    abi_file)
rpc_nodes = [main_rpc_node, fallback_rpc_node]

logger = logging.getLogger(__name__)


@use_fallback(rpc_nodes, logger, "Failed to get latest block")
def get_latest_block(rpc_node=main_rpc_node) -> int:
    return rpc_node.w3.eth.block_number


@use_fallback(rpc_nodes, logger, "Failed to get order status")
def get_is_used_order(order_id, recipient_address, amount, chain_id, rpc_node=main_rpc_node) -> bool:
    order_data = Web3.solidity_keccak(['uint256', 'address', 'uint256', 'uint8'],
                                      [order_id, Web3.to_checksum_address(recipient_address), amount, chain_id])
    is_used = rpc_node.contract.functions.transfers(order_data).call()
    return is_used


@use_fallback(rpc_nodes, logger, "Failed to get balance")
def get_balance(rpc_node=main_rpc_node) -> int:
    return rpc_node.w3.eth.get_balance(rpc_node.account.address)


def has_funds(amount: int) -> bool:
    return get_balance() >= amount


def transfer(order_id: int, destination_address: str, amount: int, chain_id: Network):
    order_id = Web3.to_int(order_id)
    amount = Web3.to_int(amount)

    unsent_tx, signed_tx = create_transfer(order_id, destination_address, amount, chain_id.value)

    gas_fee = estimate_transaction_fee(unsent_tx)
    if not has_enough_funds(amount, gas_fee):
        raise Exception("Not enough funds for transfer")

    tx_hash = send_raw_transaction(signed_tx)
    return tx_hash


# we need amount so the transaction is valid with the transfer that will be transferred
# TODO separate create_transfer_unsent_tx and sign_transaction
@use_fallback(rpc_nodes, logger, "Failed to create ethereum transfer")
def create_transfer(order_id: int, destination_address: str, amount: int, chain_id: int,
                    rpc_node=main_rpc_node):
    unsent_tx = rpc_node.contract.functions.transfer(order_id, Web3.to_checksum_address(destination_address), chain_id).build_transaction({
        "chainId": ETHEREUM_CHAIN_ID,
        "from": rpc_node.account.address,
        "nonce": get_nonce(rpc_node.w3, rpc_node.account.address),
        "value": amount,
    })
    signed_tx = rpc_node.w3.eth.account.sign_transaction(unsent_tx, private_key=rpc_node.account.key)
    return unsent_tx, signed_tx


def claim_payment(deposit_id, dst_addr, amount, value):  # TODO rename parameters to order_id and destination_address
    deposit_id = Web3.to_int(deposit_id)
    amount = Web3.to_int(amount)

    unsent_tx, signed_tx = create_claim_payment(deposit_id, dst_addr, amount, value)

    gas_fee = estimate_transaction_fee(unsent_tx)
    if not has_enough_funds(gas_fee=gas_fee):
        raise Exception("Not enough funds for claim payment")

    tx_hash = send_raw_transaction(signed_tx)
    return tx_hash


@use_fallback(rpc_nodes, logger, "Failed to create claim payment eth")
def create_claim_payment(deposit_id, destination_address, amount, value, rpc_node=main_rpc_node):
    unsent_tx = rpc_node.contract.functions.claimPayment(deposit_id, Web3.to_checksum_address(destination_address), amount).build_transaction({
        "chainId": ETHEREUM_CHAIN_ID,
        "from": rpc_node.account.address,
        "nonce": get_nonce(rpc_node.w3, rpc_node.account.address),
        "value": value,
    })
    signed_tx = rpc_node.w3.eth.account.sign_transaction(unsent_tx, private_key=rpc_node.account.key)
    return unsent_tx, signed_tx


def claim_payment_zksync(order_id: int, destination_address: str, amount: int,
                         value: int, gas_limit: int, gas_per_pub_data_byte_limit: int):
    order_id = Web3.to_int(order_id)  # I think it is not necessary because it is already an int
    amount = Web3.to_int(amount)

    unsent_tx, signed_tx = create_claim_payment_zksync(order_id, destination_address, amount,
                                                       value, gas_limit, gas_per_pub_data_byte_limit)

    return send_raw_transaction(signed_tx)


@use_fallback(rpc_nodes, logger, "Failed to create claim payment eth")
def create_claim_payment_zksync(order_id: int, destination_address: str, amount: int,
                                value: int, gas_limit: int, gas_per_pub_data_byte_limit: int,
                                rpc_node=main_rpc_node):
    unsent_tx = rpc_node.contract.functions.claimPaymentZKSync(order_id, Web3.to_checksum_address(destination_address), amount, gas_limit, gas_per_pub_data_byte_limit).build_transaction({
        "chainId": ETHEREUM_CHAIN_ID,
        "from": rpc_node.account.address,
        "nonce": get_nonce(rpc_node.w3, rpc_node.account.address),
        "value": value,
    })
    signed_tx = rpc_node.w3.eth.account.sign_transaction(unsent_tx, private_key=rpc_node.account.key)
    return unsent_tx, signed_tx


def get_nonce(w3: Web3, address):
    return w3.eth.get_transaction_count(address)


@use_fallback(rpc_nodes, logger, "Failed to estimate gas fee")
def estimate_transaction_fee(transaction, rpc_node=main_rpc_node):
    gas_limit = rpc_node.w3.eth.estimate_gas(transaction)
    fee = rpc_node.w3.eth.gas_price
    gas_fee = fee * gas_limit
    return gas_fee


@use_fallback(rpc_nodes, logger, "Failed to get gas price")
def get_gas_price(rpc_node=main_rpc_node):
    return rpc_node.w3.eth.gas_price


def is_transaction_viable(amount: int, percentage: float, gas_fee: int) -> bool:
    return gas_fee <= amount * percentage


def has_enough_funds(amount: int = 0, gas_fee: int = 0) -> bool:
    return get_balance() >= amount + gas_fee


@use_fallback(rpc_nodes, logger, "Failed to send raw transaction")
def send_raw_transaction(signed_tx, rpc_node=main_rpc_node):
    tx_hash = rpc_node.w3.eth.send_raw_transaction(signed_tx.rawTransaction)
    return tx_hash


@use_fallback(rpc_nodes, logger, "Failed to wait for transaction receipt")
def wait_for_transaction_receipt(tx_hash, rpc_node=main_rpc_node):
    rpc_node.w3.eth.wait_for_transaction_receipt(tx_hash, poll_latency=1)
