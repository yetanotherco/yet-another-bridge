
import constants
import json
from web3 import Web3, AsyncWeb3

w3 = Web3(Web3.HTTPProvider(constants.ETH_RPC_URL))

def get_latest_block() -> int:
    return w3.eth.block_number

def transfer(dst_addr, amount):
    acct = w3.eth.account.from_key(constants.ETH_PRIVATE_KEY)
    abi = json.load(open('./mm-bot/abi/YABTransfer.json'))['abi']
    yab_transfer = w3.eth.contract(address=constants.ETH_CONTRACT_ADDR, abi=abi)

    unsent_tx = billboard.functions.transfer(dst_addr, amount).build_transaction({
        "from": acct.address,
        "nonce": w3.eth.get_transaction_count(acct.address),
    })
    signed_tx = w3.eth.account.sign_transaction(unsent_tx, private_key=acct.key)
    
    tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
    w3.eth.wait_for_transaction_receipt(tx_hash)
