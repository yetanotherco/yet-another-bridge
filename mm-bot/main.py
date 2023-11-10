import ethereum
import herodotus
import json
from starknet import get_latest_order


if __name__ == '__main__':
    while True:
        # 1. Listen event on starknet
        print("[+] Listening event on starknet")
        latest_order = get_latest_order()
        print("latest order: ", latest_order)
        
        if latest_order is None:
            continue
        
        order_id = latest_order.order_id
        dst_addr = latest_order.recipient_address
        amount = latest_order.amount
        
        # 2. Transfer eth on ethereum
        # (bridging is complete for the user)
        print("[+] Transfering eth on ethereum")
        # TODO check the tx receipt
        ethereum.transfer(order_id, dst_addr, amount)
        print("[+] Transfer complete")
        
        # 3. Call herodotus to prove
        # extra: validate w3.eth.get_storage_at(addr, pos) before calling herodotus
        block = ethereum.get_latest_block()
        print("[+] Proving block {}".format(block))
        task_id = herodotus.herodotus_prove(block, order_id)
        print("[+] Block being proved with task id: {}".format(task_id))
        
        # 4. Poll herodotus to check task status
        print("[+] Polling herodotus for task status")
        completed = herodotus.herodotus_poll_status(task_id)
        print("[+] Task completed")
        
        # 5. Withdraw eth from starknet
        # (bridging is complete for the mm)
        if completed:
            print("[+] Withdraw eth from starknet")
            # TODO
