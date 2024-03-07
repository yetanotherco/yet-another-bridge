import asyncio
import logging

from models.order import Order
from models.order_status import OrderStatus
from services import ethereum
from services.order_service import OrderService
from services.overall_fee_calculator import estimate_overall_fee
from services.payment_claimer.payment_claimer import PaymentClaimer


class OrderExecutor:

    def __init__(self, order_service: OrderService,
                 payment_claimer: PaymentClaimer,
                 eth_lock: asyncio.Lock, herodotus_semaphore: asyncio.Semaphore,
                 max_eth_transfer_wei: int):
        self.logger = logging.getLogger(__name__)
        self.order_service: OrderService = order_service
        self.payment_claimer: PaymentClaimer = payment_claimer
        self.eth_lock: asyncio.Lock = eth_lock
        self.herodotus_semaphore: asyncio.Semaphore = herodotus_semaphore
        self.MAX_ETH_TRANSFER_WEI: int = max_eth_transfer_wei

    def execute(self, order: Order):
        """
        Execute the order
        """
        asyncio.create_task(self.process_order(order), name=order.summary())

    async def process_order(self, order: Order):
        """
        Process the order
        """
        try:
            self.logger.info(f"[+] Processing order: {order}")
            # 1. Check if the order fee is enough
            if order.status is OrderStatus.PENDING:
                estimated_fee = await estimate_overall_fee(order)
                if order.get_int_fee() < estimated_fee:
                    self.logger.error(f"[-] Order fee is too low: {order.get_int_fee()} < {estimated_fee}")
                    self.order_service.set_order_dropped(order)
                    return
                self.order_service.set_order_processing(order)

            # 1.5. Check if order amount is too high
            if order.amount > self.MAX_ETH_TRANSFER_WEI:
                self.logger.error(f"[-] Order amount is too high: {order.amount}")
                self.order_service.set_order_dropped(order)
                return

            # 2. Transfer eth on ethereum
            # (bridging is complete for the user)
            if order.status in [OrderStatus.PROCESSING, OrderStatus.TRANSFERRING]:
                async with self.eth_lock:
                    if order.status is OrderStatus.PROCESSING:
                        await self.transfer(order)

                    # 2.5. Wait for transfer
                    if order.status is OrderStatus.TRANSFERRING:
                        await self.wait_transfer(order)

            if order.status in [OrderStatus.FULFILLED, OrderStatus.PROVING]:
                # async with self.herodotus_semaphore if using_herodotus() else eth_lock:
                # TODO implement using_herodotus
                # 3. Call payment claymer to prove
                if order.status is OrderStatus.FULFILLED:
                    await self.payment_claimer.send_payment_claim(order, self.order_service)

                # 4. Poll herodotus to check task status
                if order.status is OrderStatus.PROVING:
                    await self.payment_claimer.wait_for_payment_claim(order, self.order_service)

            # 5. Claim payment eth from starknet
            # (bridging is complete for the mm)
            if order.status is OrderStatus.PROVED:
                await self.payment_claimer.close_payment_claim(order, self.order_service)

            if order.status is OrderStatus.COMPLETED:
                self.logger.info(f"[+] Order {order.order_id} completed")
        except Exception as e:
            self.logger.error(f"[-] Error: {e}")
            self.order_service.set_order_failed(order, str(e))

    async def transfer(self, order: Order):
        self.logger.info(f"[+] Transferring eth on ethereum")
        # in case it's processed on ethereum, but not processed on starknet
        tx_hash = await asyncio.to_thread(ethereum.transfer, order.order_id, order.recipient_address,
                                          order.get_int_amount())
        self.order_service.set_order_transferring(order, tx_hash)
        self.logger.info(f"[+] Transfer tx hash: {tx_hash.hex()}")

    async def wait_transfer(self, order: Order):
        await asyncio.to_thread(ethereum.wait_for_transaction_receipt, order.tx_hash)
        self.order_service.set_order_fulfilled(order)
        self.logger.info(f"[+] Transfer complete")
