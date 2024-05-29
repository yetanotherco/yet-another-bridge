import asyncio
import logging

from src.models.order import Order
from src.models.order_status import OrderStatus
from src.services.fee_calculators.fee_calculator import FeeCalculator
from src.services.order_service import OrderService
from src.services.payment_claimer.payment_claimer import PaymentClaimer
from src.services.senders.ethereum_sender import EthereumSender


class OrderExecutor:

    def __init__(self, order_service: OrderService,
                 ethereum_sender: EthereumSender,
                 payment_claimer: PaymentClaimer,
                 fee_calculator: FeeCalculator,
                 eth_lock: asyncio.Lock, herodotus_semaphore: asyncio.Semaphore,
                 max_eth_transfer_wei: int):
        self.logger = logging.getLogger(__name__)
        self.order_service: OrderService = order_service
        self.sender: EthereumSender = ethereum_sender
        self.payment_claimer: PaymentClaimer = payment_claimer
        self.fee_calculator: FeeCalculator = fee_calculator
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
                estimated_fee = await self.fee_calculator.estimate_overall_fee(order)
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
                        await self.sender.transfer(order)

                    # 2.5. Wait for transfer
                    if order.status is OrderStatus.TRANSFERRING:
                        await self.sender.wait_transfer(order)

            if order.status in [OrderStatus.FULFILLED, OrderStatus.PROVING]:
                # async with self.herodotus_semaphore if using_herodotus() else eth_lock:
                # TODO implement using_herodotus
                async with self.eth_lock:
                    # 3. Call payment claimer to prove
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
