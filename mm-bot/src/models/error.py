from datetime import datetime

from sqlalchemy import Column, Integer, ForeignKey, String, DateTime
from sqlalchemy.orm import relationship, Mapped

from config.database_config import Base
from models.order import Order


class Error(Base):
    __tablename__ = "error"
    id: int = Column(Integer, primary_key=True, nullable=False)
    order_id: int = Column(Integer, ForeignKey("orders.order_id"), nullable=False)
    order: Mapped[Order] = relationship("Order")
    message: str = Column(String, nullable=False)
    created_at: datetime = Column(DateTime, nullable=False, default=datetime.now())
