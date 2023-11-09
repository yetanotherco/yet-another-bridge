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
        
        if (latest_order): 
            print("[+] Event received \n {}", latest_order)
            dst_addr = '0x8fc7071cd97B9FbF5e9f09294B014EA27c39b3d8'# latest_order.recipient_address
            amount = latest_order.amount

            # 2. Transfer eth on ethereum
            # (bridging is complete for the user)
            print("[+] Transfering eth on ethereum")
            # TODO check the tx receipt
            ethereum.transfer(dst_addr, amount)
            print("[+] Transfer complete")
            
            # 3. Call herodotus to prove
            # extra: validate w3.eth.get_storage_at(addr, pos) before calling herodotus
            block = ethereum.get_latest_block()
            print("[+] Proving block {}".format(block))
            task_id = herodotus.herodotus_prove(block)
            print("[+] Block being proved with task id: {}".format(task_id))
            
            # 4. Poll herodotus to check task status
            print("[+] Polling herodotus for task status")
            completed = herodotus.herodotus_poll_status(task_id)
            print("[+] Task completed")
            
            # 5. Withdraw eth from starknet
            # (bridging is complete for the mm)
            if completed:
                print("[+] Withdraw eth from starknet")
                # starknet_invoke_result = starknet_invoke()
                # call starknet escrow withdraw 

            
