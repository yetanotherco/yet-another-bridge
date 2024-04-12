import decimal
from datetime import datetime

from hexbytes import HexBytes
from sqlalchemy import Column, Integer, String, DateTime, Enum, Numeric, LargeBinary

from config.database_config import Base
from models.network import Network
from models.order_status import OrderStatus
from models.set_order_event import SetOrderEvent


class Order(Base):
    __tablename__ = "orders"
    order_id: int = Column(Integer, primary_key=True, nullable=False)
    origin_network: Network = Column(Enum(Network), primary_key=True, nullable=False)

    from_address: str = Column(String(64), nullable=False)
    recipient_address: str = Column(String(42), nullable=False)
    amount: decimal = Column(Numeric(78, 0), nullable=False)
    fee: decimal = Column(Numeric(78, 0), nullable=False)

    status: OrderStatus = Column(Enum(OrderStatus), nullable=False, default=OrderStatus.PENDING)
    failed: bool = Column(Integer, nullable=False, default=False)

    set_order_tx_hash: HexBytes = Column(LargeBinary, nullable=False)
    transfer_tx_hash: HexBytes = Column(LargeBinary, nullable=True)
    claim_tx_hash: HexBytes = Column(LargeBinary, nullable=True)

    herodotus_task_id: str = Column(String, nullable=True)
    herodotus_block: int = Column(Integer, nullable=True)
    herodotus_slot: HexBytes = Column(LargeBinary, nullable=True)

    created_at: datetime = Column(DateTime, nullable=False, server_default="clock_timestamp()")
    transferred_at: datetime = Column(DateTime, nullable=True)
    completed_at: datetime = Column(DateTime, nullable=True)

    def __str__(self):
        return f"[{self.origin_network.name} ~ {self.order_id}], recipient: {self.recipient_address}, amount: {self.amount}, fee: {self.fee}, status: {self.status.value}"

    def __repr__(self):
        return str(self)

    def get_int_amount(self) -> int:
        return int(self.amount)

    def get_int_fee(self) -> int:
        return int(self.fee)

    def summary(self) -> str:
        """
        Returns a string with the origin network and order id
        """
        return f"{self.origin_network.name} ~ {self.order_id}"

    @staticmethod
    def from_set_order_event(set_order_event: SetOrderEvent):
        return Order(
            order_id=set_order_event.order_id,
            from_address=set_order_event.from_address,
            origin_network=set_order_event.origin_network,
            recipient_address=set_order_event.recipient_address,
            amount=set_order_event.amount,
            fee=set_order_event.fee,
            set_order_tx_hash=set_order_event.set_order_tx_hash,
            status=OrderStatus.COMPLETED if set_order_event.is_used else OrderStatus.PENDING
        )
