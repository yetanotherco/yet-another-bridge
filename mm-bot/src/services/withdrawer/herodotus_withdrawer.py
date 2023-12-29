import asyncio

from web3 import Web3

from models.order import Order
from persistence.order_dao import OrderDao
from services import ethereum, herodotus, starknet
from services.withdrawer.withdrawer import Withdrawer


class HerodotusWithdrawer(Withdrawer):
    """
    Initialize the proof on herodotus
    """

    async def send_withdraw(self, order: Order, order_dao: OrderDao):
        block = ethereum.get_latest_block()
        index = Web3.solidity_keccak(['uint256', 'uint256', 'uint256'],
                                     [order.order_id, int(order.recipient_address, 0), order.get_int_amount()])
        slot = Web3.solidity_keccak(['uint256', 'uint256'], [int(index.hex(), 0), 0])
        self.logger.debug(f"[+] Index: {index.hex()}")
        self.logger.debug(f"[+] Slot: {slot.hex()}")
        self.logger.debug(f"[+] Proving block {block}")
        task_id = await herodotus.herodotus_prove(block, order.order_id, slot)
        order_dao.set_order_proving_herodotus(order, task_id, block, slot)
        self.logger.info(f"[+] Block being proved with task id: {task_id}")

    """
    Wait for the prove to be done on herodotus
    """

    async def wait_for_withdraw(self, order: Order, order_dao: OrderDao):
        self.logger.info(f"[+] Polling herodotus for task status")
        # avoid weird case where herodotus insta says done
        await asyncio.sleep(10)
        completed = await herodotus.herodotus_poll_status(order.herodotus_task_id)
        if completed:
            order_dao.set_order_proved(order)
            self.logger.info(f"[+] Task completed")

    """
    Makes the withdraw on starknet
    """

    async def close_withdraw(self, order: Order, order_dao: OrderDao):
        self.logger.info(f"[+] Withdrawing eth from starknet")
        await starknet.withdraw(order.order_id, order.herodotus_block, order.herodotus_slot)
        order_dao.set_order_completed(order)
        self.logger.info(f"[+] Withdraw complete")
