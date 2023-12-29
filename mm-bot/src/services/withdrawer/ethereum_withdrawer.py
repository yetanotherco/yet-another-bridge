import asyncio

from config import constants
from models.order import Order
from persistence.order_dao import OrderDao
from services import ethereum, starknet
from services.withdrawer.withdrawer import Withdrawer


class EthereumWithdrawer(Withdrawer):
    """
    Makes the withdrawal on ethereum
    Sends a 'withdraw' transaction to ethereum smart contract
    """

    async def send_withdraw(self, order: Order, order_dao: OrderDao):
        self.logger.info(f"[+] Sending withdraw tx to ethereum")
        try:
            tx_hash = await asyncio.to_thread(ethereum.withdraw,
                                              order.order_id, order.recipient_address, order.get_int_amount())
            order_dao.set_order_proving_ethereum(order, tx_hash)
        except Exception as e:
            self.logger.error(f"[-] Withdraw failed: {e}")

    """
    Waits for the withdraw transaction to be confirmed on ethereum
    """

    async def wait_for_withdraw(self, order: Order, order_dao: OrderDao):
        await asyncio.to_thread(ethereum.wait_for_transaction_receipt, order.eth_withdraw_tx_hash)
        order_dao.set_order_proved(order)
        self.logger.info(f"[+] Withdraw tx confirmed")

    """
    Closes the withdrawal setting the order as completed
    """

    async def close_withdraw(self, order: Order, order_dao: OrderDao):
        retries = 0
        while retries < constants.MAX_RETRIES:
            if await starknet.get_is_used_order(order.order_id):
                break
            retries += 1
            await asyncio.sleep(10)
        self.logger.info(f"[+] Withdraw complete")
        order_dao.set_order_completed(order)
