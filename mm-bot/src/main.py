import asyncio
import logging
from web3 import Web3

from config.database_config import get_db
from models.order import Order
from models.order_status import OrderStatus
from persistence.order_dao import OrderDao
from services import ethereum
from services import herodotus
from services import starknet
from config.logging_config import setup_logger

setup_logger()
logger = logging.getLogger(__name__)
SLEEP_TIME = 5


async def run():
    logger.info(f"[+] Listening events on starknet")
    order_dao = OrderDao(get_db())
    eth_lock = asyncio.Lock()

    try:
        while True:
            # 1. Listen event on starknet
            set_order_events: set = await starknet.get_latest_unfulfilled_orders()
            if len(set_order_events) == 0:
                logger.debug(f"[+] No new events")
                await asyncio.sleep(SLEEP_TIME)
                continue

            for set_order_event in set_order_events:
                order_id = set_order_event.order_id
                recipient_addr = set_order_event.recipient_address
                amount = set_order_event.amount
                if order_dao.already_exists(order_id):
                    logger.debug(f"[+] Order already processed: {order_id}")
                    continue

                try:
                    order = Order(order_id=order_id, recipient_address=recipient_addr, amount=amount)
                    order = order_dao.create_order(order)
                    logger.info(f"[+] New order: {order}")
                except Exception as e:
                    logger.error(f"[-] Error: {e}")
                    continue

                asyncio.create_task(process_order(order, eth_lock, order_dao), name=f"Order-{order_id}")

            await asyncio.sleep(SLEEP_TIME)
    except Exception as e:
        logger.error(f"[-] Error: {e}")


async def process_order(order: Order, eth_lock: asyncio.Lock, order_dao: OrderDao):
    order_dao.update_order(order, OrderStatus.PROCESSING)
    # 2. Transfer eth on ethereum
    # (bridging is complete for the user)
    async with eth_lock:
        try:
            await transfer(order, eth_lock, order_dao)
        except Exception as e:
            logger.error(f"[-] Transfer failed: {e}")

    # 3. Call herodotus to prove
    # extra: validate w3.eth.get_storage_at(addr, pos) before calling herodotus
    task_id, block, slot = await prove(order, order_dao)

    # 4. Poll herodotus to check task status
    completed = await wait_herodotus_prove(order, order_dao)

    # 5. Withdraw eth from starknet
    # (bridging is complete for the mm)
    if completed:
        await withdraw(order, block, slot, order_dao)


async def transfer(order: Order, eth_lock: asyncio.Lock, order_dao: OrderDao):
    logger.info(f"[+] Transferring eth on ethereum")
    # in case it's processed on ethereum, but not processed on starknet
    tx_hash_hex = await asyncio.to_thread(ethereum.transfer, order.order_id, order.recipient_address, order.get_int_amount())
    order_dao.update_order(order, OrderStatus.FULFILLED)
    logger.info(f"[+] Transfer tx hash: 0x{tx_hash_hex}")
    logger.info(f"[+] Transfer complete")


async def prove(order: Order, order_dao: OrderDao):
    block = ethereum.get_latest_block()
    index = Web3.solidity_keccak(['uint256', 'uint256', 'uint256'],
                                 [order.order_id, int(order.recipient_address, 0), order.get_int_amount()])
    slot = Web3.solidity_keccak(['uint256', 'uint256'], [int(index.hex(), 0), 0])
    logger.debug(f"[+] Index: {index.hex()}")
    logger.debug(f"[+] Slot: {slot.hex()}")
    logger.debug(f"[+] Proving block {block}")
    task_id = await herodotus.herodotus_prove(block, order.order_id, slot)
    order_dao.update_order(order, OrderStatus.PROVING)
    order_dao.set_order_herodotus_task_id(order, task_id)
    logger.info(f"[+] Block being proved with task id: {task_id}")
    return task_id, block, slot


async def wait_herodotus_prove(order: Order, order_dao: OrderDao):
    logger.info(f"[+] Polling herodotus for task status")
    # avoid weird case where herodotus insta says done
    await asyncio.sleep(10)
    completed = await herodotus.herodotus_poll_status(order.herodotus_task_id)
    order_dao.update_order(order, OrderStatus.PROVED)
    logger.info(f"[+] Task completed")
    return completed


async def withdraw(order: Order, block, slot, order_dao: OrderDao):
    logger.info(f"[+] Withdrawing eth from starknet")
    await starknet.withdraw(order.order_id, block, slot)
    order_dao.update_order(order, OrderStatus.COMPLETED)
    logger.info(f"[+] Withdraw complete")


if __name__ == '__main__':
    asyncio.run(run())
