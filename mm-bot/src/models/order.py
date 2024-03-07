import decimal
from datetime import datetime

from hexbytes import HexBytes
from sqlalchemy import Column, Integer, String, DateTime, Enum, Numeric, LargeBinary

from config.database_config import Base
from models.network import Network
from models.order_status import OrderStatus


class Order(Base):
    __tablename__ = "orders"
    order_id: int = Column(Integer, primary_key=True, nullable=False)
    origin_network: Network = Column(Enum(Network), primary_key=True, nullable=False)

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
        return f"[{self.origin_network.value} ~ {self.order_id}], recipient: {self.recipient_address}, amount: {self.amount}, fee: {self.fee}, status: {self.status.value}"

    def __repr__(self):
        return str(self)

    def get_int_amount(self) -> int:
        return int(self.amount)

    def get_int_fee(self) -> int:
        return int(self.fee)

    def summary(self) -> str:  # TODO set a better name
        """
        Returns a string with the origin network and order id
        """
        return f"{self.origin_network.value} ~ {self.order_id}"
