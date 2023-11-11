import asyncio
import ethereum
import herodotus
import json
import starknet
import time
from web3 import Web3

async def run():
    print("[+] Listening events on starknet")
    while True:
        # 1. Listen event on starknet
        latest_order = await starknet.get_latest_unfulfilled_order()
        if latest_order is None:
            continue

        print("New event: ", latest_order)
        
        order_id = latest_order.order_id
        dst_addr = latest_order.recipient_address
        amount = latest_order.amount
        
        # 2. Transfer eth on ethereum
        # (bridging is complete for the user)
        print("[+] Transfering eth on ethereum")
        try:
            # in case it's processed on ethereum, but not processed on starknet
            ethereum.transfer(order_id, dst_addr, amount)
        except Exception as e:
            print(e)
        print("[+] Transfer complete")
        
        # 3. Call herodotus to prove
        # extra: validate w3.eth.get_storage_at(addr, pos) before calling herodotus
        block = ethereum.get_latest_block()
        slot = Web3.solidity_keccak(['uint256', 'uint256'], [order_id, 0])
        print("[+] Proving block {}".format(block))
        task_id = herodotus.herodotus_prove(block, order_id, slot)
        print("[+] Block being proved with task id: {}".format(task_id))
        
        # 4. Poll herodotus to check task status
        print("[+] Polling herodotus for task status")
        # avoid weird case where herodotus insta says done
        time.sleep(10)
        completed = herodotus.herodotus_poll_status(task_id)
        print("[+] Task completed")
        
        # 5. Withdraw eth from starknet
        # (bridging is complete for the mm)
        if completed:
            print("[+] Withdraw eth from starknet")
            await starknet.withdraw(order_id, block, slot)

if __name__ == '__main__':
    asyncio.run(run())
