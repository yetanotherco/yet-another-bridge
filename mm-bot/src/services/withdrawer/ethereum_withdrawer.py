import asyncio

from starknet_py.hash.selector import get_selector_from_name

from config import constants
from models.order import Order
from services import ethereum, starknet
from services.order_service import OrderService
from services.withdrawer.withdrawer import Withdrawer


class EthereumWithdrawer(Withdrawer):
    """
    Makes the withdrawal on ethereum
    Sends a 'withdraw' transaction to ethereum smart contract
    """

    async def send_withdraw(self, order: Order, order_service: OrderService):
        self.logger.info(f"[+] Sending withdraw tx to ethereum")
        order_id, recipient_address, amount = order.order_id, order.recipient_address, order.get_int_amount()
        value = await self.estimate_withdraw_fallback_message_fee(order_id, recipient_address, amount)
        tx_hash = await asyncio.to_thread(ethereum.withdraw,
                                          order_id, recipient_address, amount, value)
        order_service.set_order_proving_ethereum(order, tx_hash)
        self.logger.info(f"[+] Withdraw tx hash: {tx_hash.hex()}")

    @staticmethod
    async def estimate_withdraw_fallback_message_fee(order_id, recipient_address, amount):
        from_address = constants.ETH_CONTRACT_ADDR
        to_address = constants.SN_CONTRACT_ADDR
        entry_point_selector = hex(get_selector_from_name("withdraw_fallback"))
        payload = [
            hex(order_id),
            "0x0",
            recipient_address,
            hex(amount),
            "0x0"
        ]
        return await starknet.estimate_message_fee(from_address, to_address, entry_point_selector, payload)

    """
    Waits for the withdraw transaction to be confirmed on ethereum
    """

    async def wait_for_withdraw(self, order: Order, order_service: OrderService):
        await asyncio.to_thread(ethereum.wait_for_transaction_receipt, order.eth_withdraw_tx_hash)
        order_service.set_order_proved(order)
        self.logger.info(f"[+] Withdraw tx confirmed")

    """
    Closes the withdrawal setting the order as completed
    """

    async def close_withdraw(self, order: Order, order_service: OrderService):
        retries = 0
        while retries < constants.MAX_RETRIES:
            if await asyncio.to_thread(ethereum.get_is_used_order,
                                       order.order_id, order.recipient_address, order.get_int_amount()):
                break
            retries += 1
            await asyncio.sleep(10)
        self.logger.info(f"[+] Withdraw complete")
        order_service.set_order_completed(order)
