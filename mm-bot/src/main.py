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
        orders = order_dao.get_incomplete_orders()
        for order in orders:
            create_order_task(order, eth_lock, order_dao)

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

                create_order_task(order, eth_lock, order_dao)

            await asyncio.sleep(SLEEP_TIME)
    except Exception as e:
        logger.error(f"[-] Error: {e}")


def create_order_task(order: Order, eth_lock: asyncio.Lock, order_dao: OrderDao):
    asyncio.create_task(process_order(order, eth_lock, order_dao), name=f"Order-{order.order_id}")


async def process_order(order: Order, eth_lock: asyncio.Lock, order_dao: OrderDao):
    if order.status is OrderStatus.PENDING:
        order_dao.set_order_processing(order)

    # 2. Transfer eth on ethereum
    # (bridging is complete for the user)
    if order.status is OrderStatus.PROCESSING:
        async with eth_lock:
            try:
                await transfer(order, order_dao)
            except Exception as e:
                logger.error(f"[-] Transfer failed: {e}")

    # 2.5. Wait for transfer
    if order.status is OrderStatus.TRANSFERRING:
        await wait_transfer(order, order_dao)

    # 3. Call herodotus to prove
    # extra: validate w3.eth.get_storage_at(addr, pos) before calling herodotus
    if order.status is OrderStatus.FULFILLED:
        await prove(order, order_dao)

    # 4. Poll herodotus to check task status
    if order.status is OrderStatus.PROVING:
        await wait_herodotus_prove(order, order_dao)

    # 5. Withdraw eth from starknet
    # (bridging is complete for the mm)
    if order.status is OrderStatus.PROVED:
        await withdraw(order, order_dao)


async def transfer(order: Order, order_dao: OrderDao):
    logger.info(f"[+] Transferring eth on ethereum")
    # in case it's processed on ethereum, but not processed on starknet
    order_dao.set_order_transferring(order, None)
    tx_hash = await asyncio.to_thread(ethereum.transfer, order.order_id, order.recipient_address, order.get_int_amount())
    order_dao.set_order_transferring(order, tx_hash)
    logger.info(f"[+] Transfer tx hash: {tx_hash.hex()}")


async def wait_transfer(order: Order, order_dao: OrderDao):
    await asyncio.to_thread(ethereum.wait_for_transaction_receipt, order.tx_hash)
    order_dao.set_order_fulfilled(order)
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
    order_dao.set_order_proving(order, task_id, block, slot)
    logger.info(f"[+] Block being proved with task id: {task_id}")


async def wait_herodotus_prove(order: Order, order_dao: OrderDao):
    logger.info(f"[+] Polling herodotus for task status")
    # avoid weird case where herodotus insta says done
    await asyncio.sleep(10)
    completed = await herodotus.herodotus_poll_status(order.herodotus_task_id)
    if completed:
        order_dao.set_order_proved(order)
        logger.info(f"[+] Task completed")


async def withdraw(order: Order, order_dao: OrderDao):
    logger.info(f"[+] Withdrawing eth from starknet")
    await starknet.withdraw(order.order_id, order.herodotus_block, order.herodotus_slot)
    order_dao.set_order_completed(order)
    logger.info(f"[+] Withdraw complete")


if __name__ == '__main__':
    asyncio.run(run())
