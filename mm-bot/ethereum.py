import logging
import constants
import json
import os
from web3 import Web3, AsyncWeb3

main_w3 = Web3(Web3.HTTPProvider(constants.ETH_RPC_URL))
fallback_w3 = Web3(Web3.HTTPProvider(constants.ETH_FALLBACK_RPC_URL))
w3_clients = [main_w3,fallback_w3]

logger = logging.getLogger(__name__)


def get_latest_block() -> int:
    for w3 in w3_clients:
        try:
            return w3.eth.block_number
        except Exception as exception:
            logger.error(f"[-] Failed to get block number from node: {exception}")
    logger.error(f"[-] Failed to get block number from all nodes")


def transfer(deposit_id, dst_addr, amount):
    for w3 in w3_clients:
        try:
            acct = w3.eth.account.from_key(constants.ETH_PRIVATE_KEY)
            # get only the abi not the entire file
            abi = json.load(open(os.path.dirname(os.path.realpath(__file__)) + '/abi/YABTransfer.json'))['abi']

            yab_transfer = w3.eth.contract(address=constants.ETH_CONTRACT_ADDR, abi=abi)
            dst_addr_bytes = int(dst_addr, 0)
            deposit_id = Web3.to_int(deposit_id)
            amount = Web3.to_int(amount)
            # we need amount so the transaction is valid with the transfer that will be transferred
            unsent_tx = yab_transfer.functions.transfer(deposit_id, dst_addr_bytes, amount).build_transaction({
                "chainId": 5,
                "from": acct.address,
                "nonce": w3.eth.get_transaction_count(acct.address),
                "value": amount,
            })
            signed_tx = w3.eth.account.sign_transaction(unsent_tx, private_key=acct.key)

            tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
            w3.eth.wait_for_transaction_receipt(tx_hash)
            return tx_hash.hex()
        except Exception as exception:
            logger.error(f"[-] Failed to transfer eth on node: {exception}")
    logger.error(f"[-] Failed to transfer eth on all nodes")
    raise Exception("Failed to transfer eth on all nodes")

