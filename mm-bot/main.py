import asyncio
import logging
import ethereum
import herodotus
import json
import starknet
import time
from web3 import Web3
from logging_config import setup_logger

setup_logger()
logger = logging.getLogger(__name__)


async def run():
    logger.info(f"[+] Listening events on starknet")

    while True:
        # 1. Listen event on starknet
        latest_order = await starknet.get_latest_unfulfilled_order()
        if latest_order is None:
            continue

        logger.info(f"[+] New event: {latest_order}")

        order_id = latest_order.order_id
        dst_addr = latest_order.recipient_address
        amount = latest_order.amount

        # 2. Transfer eth on ethereum
        # (bridging is complete for the user)
        logger.info(f"[+] Transferring eth on ethereum")
        try:
            # in case it's processed on ethereum, but not processed on starknet
            ethereum.transfer(order_id, dst_addr, amount)
        except Exception as e:
            logger.error(f"[-] Transfer failed: {e}")
        logger.info(f"[+] Transfer complete")

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
