import decimal
from datetime import datetime

from hexbytes import HexBytes
from sqlalchemy import Column, Integer, String, DateTime, Enum, Numeric, LargeBinary

from config.database_config import Base
from models.order_status import OrderStatus


class Order(Base):
    __tablename__ = "orders"
    order_id: int = Column(Integer, primary_key=True, nullable=False)
    recipient_address: str = Column(String(42), nullable=False)
    amount: decimal = Column(Numeric(78, 0), nullable=False)
    status: OrderStatus = Column(Enum(OrderStatus), nullable=False, default=OrderStatus.PENDING)
    tx_hash: HexBytes = Column(LargeBinary, nullable=True)
    herodotus_task_id: str = Column(String, nullable=True)
    herodotus_block: int = Column(Integer, nullable=True)
    herodotus_slot: HexBytes = Column(LargeBinary, nullable=True)
    eth_withdraw_tx_hash: HexBytes = Column(LargeBinary, nullable=True)
    created_at: datetime = Column(DateTime, nullable=False, default=datetime.now())

    def __str__(self):
        return f"order_id:{self.order_id}, recipient: {self.recipient_address}, amount: {self.amount}, status: {self.status.value}, herodotus_task_id: {self.herodotus_task_id}"

    def get_int_amount(self) -> int:
        return int(self.amount)
