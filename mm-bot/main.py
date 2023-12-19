import asyncio
import logging

import ethereum
import herodotus
import json
import starknet
from web3 import Web3
from logging_config import setup_logger

setup_logger()
logger = logging.getLogger(__name__)
SLEEP_TIME = 5


async def run():
    logger.info(f"[+] Listening events on starknet")
    eth_lock = asyncio.Lock()
    orders = set()

    try:
        while True:
            # TODO refactor with new indexer
            # 1. Listen event on starknet
            latest_orders: set = await starknet.get_latest_unfulfilled_orders()
            if len(latest_orders) == 0:
                logger.debug(f"[+] No new events")
                await asyncio.sleep(SLEEP_TIME)
                continue

            for order in latest_orders:
                order_id = order.order_id
                dst_addr = order.recipient_address
                amount = order.amount

                if order_id in orders:
                    logger.debug(f"[+] Order already processed: {order_id}")
                    continue

                logger.info(f"[+] New order: {order}")

                orders.add(order_id)
                asyncio.create_task(process_order(order_id, dst_addr, amount, eth_lock), name=f"Order-{order_id}")

            await asyncio.sleep(SLEEP_TIME)
    except Exception as e:
        logger.error(f"[-] Error: {e}")
    logger.info(f"[+] All threads finished")


async def process_order(order_id, dst_addr, amount, eth_lock):
    # 2. Transfer eth on ethereum
    # (bridging is complete for the user)
    logger.info(f"[+] Transferring eth on ethereum")
    async with eth_lock:
        try:
            # in case it's processed on ethereum, but not processed on starknet
            tx_hash_hex = await asyncio.to_thread(ethereum.transfer, order_id, dst_addr, amount)
            logger.info(f"[+] Transfer tx hash: 0x{tx_hash_hex}")
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
    task_id = await herodotus.herodotus_prove(block, order_id, slot)
    logger.info(f"[+] Block being proved with task id: {task_id}")

    # 4. Poll herodotus to check task status
    logger.info(f"[+] Polling herodotus for task status")
    # avoid weird case where herodotus insta says done
    await asyncio.sleep(10)
    completed = await herodotus.herodotus_poll_status(task_id)
    logger.info(f"[+] Task completed")

    # 5. Withdraw eth from starknet
    # (bridging is complete for the mm)
    if completed:
        logger.info(f"[+] Withdraw eth from starknet")
        await starknet.withdraw(order_id, block, slot)


if __name__ == '__main__':
    asyncio.run(run())
