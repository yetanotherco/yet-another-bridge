import asyncio
import logging
import threading

import ethereum
import herodotus
import json
import starknet
import time
from web3 import Web3
from logging_config import setup_logger

setup_logger()
logger = logging.getLogger(__name__)
SLEEP_TIME = 5


async def run():
    logger.info(f"[+] Listening events on starknet")
    eth_lock = threading.Lock()
    threads = []
    orders = set()

    try:
        while True:
            # TODO refactor with new indexer
            # 1. Listen event on starknet
            latest_orders: set = await starknet.get_latest_unfulfilled_orders()
            if len(latest_orders) == 0:
                logger.debug(f"[+] No new events")
                time.sleep(SLEEP_TIME)
                continue

            for order in latest_orders:
                logger.info(f"[+] New event: {order}")

                order_id = order.order_id
                dst_addr = order.recipient_address
                amount = order.amount

                if order_id in orders:
                    logger.info(f"[+] Order already processed: {order_id}")
                    continue

                orders.add(order_id)
                t = threading.Thread(target=asyncio.run, args=(process_order(order_id, dst_addr, amount, eth_lock),))
                threads.append(t)
                t.start()

            time.sleep(SLEEP_TIME)
    except Exception as e:
        logger.error(f"[-] Error: {e}")
        logger.info(f"[+] Waiting for threads to finish")
        for t in threads:
            t.join()
    logger.info(f"[+] All threads finished")


async def process_order(order_id, dst_addr, amount, eth_lock):
    # 2. Transfer eth on ethereum
    # (bridging is complete for the user)
    logger.info(f"[+] Transferring eth on ethereum")
    with eth_lock:
        try:
            # in case it's processed on ethereum, but not processed on starknet
            ethereum.transfer(order_id, dst_addr, amount)
            logger.info(f"[+] Transfer complete")
        except Exception as e:
            logger.error(f"[-] Transfer failed: {e}")

    # 3. Call herodotus to prove
    # extra: validate w3.eth.get_storage_at(addr, pos) before calling herodotus
    block = ethereum.get_latest_block()
    index = Web3.solidity_keccak(['uint256', 'uint256', 'uint256'],
                                 [order_id, int(dst_addr, 0), amount])
    slot = Web3.solidity_keccak(['uint256', 'uint256'], [int(index.hex(), 0), 0])
    logger.info(f"[+] Index: {index.hex()}")
    logger.info(f"[+] Slot: {slot.hex()}")
    logger.info(f"[+] Proving block {block}")
    task_id = herodotus.herodotus_prove(block, order_id, slot)
    logger.info(f"[+] Block being proved with task id: {task_id}")

    # 4. Poll herodotus to check task status
    logger.info(f"[+] Polling herodotus for task status")
    # avoid weird case where herodotus insta says done
    time.sleep(10)
    completed = herodotus.herodotus_poll_status(task_id)
    logger.info(f"[+] Task completed")

    # 5. Withdraw eth from starknet
    # (bridging is complete for the mm)
    if completed:
        logger.info(f"[+] Withdraw eth from starknet")
        await starknet.withdraw(order_id, block, slot)


if __name__ == '__main__':
    asyncio.run(run())
