
import constants
import json
import os
from web3 import Web3, AsyncWeb3

w3 = Web3(Web3.HTTPProvider(constants.ETH_RPC_URL))

def get_latest_block() -> int:
    return w3.eth.block_number

def transfer(deposit_id, dst_addr, amount):
    acct = w3.eth.account.from_key(constants.ETH_PRIVATE_KEY)
    # get only the abi not the entire file
    abi = json.load(open(os.path.dirname(os.path.realpath(__file__))+'/abi/YABTransfer.json'))['abi']

    yab_transfer = w3.eth.contract(address=constants.ETH_CONTRACT_ADDR, abi=abi)
    dst_addr_bytes = int(dst_addr, 0)
    deposit_id = Web3.to_int(deposit_id)
    amount = Web3.to_int(amount)
    # we need amount so the transaction is valid with the trasnfer that will be transfered
    unsent_tx = yab_transfer.functions.transfer(deposit_id, dst_addr_bytes, amount).build_transaction({
        "chainId": 5,
        "from": acct.address,
        "nonce": w3.eth.get_transaction_count(acct.address),
        "value": amount,
    })
    signed_tx = w3.eth.account.sign_transaction(unsent_tx, private_key=acct.key)
    
    tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
    w3.eth.wait_for_transaction_receipt(tx_hash)
    print("[+] Transfer tx hash: 0x{}".format(tx_hash.hex()))
