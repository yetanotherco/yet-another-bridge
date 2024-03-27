from datetime import datetime

from sqlalchemy import Column, Integer, ForeignKeyConstraint, String, DateTime, Enum
from sqlalchemy.orm import relationship, Mapped

from config.database_config import Base
from models.network import Network
from models.order import Order


class Error(Base):
    __tablename__ = "error"
    id: int = Column(Integer, primary_key=True, nullable=False)
    order_id: int = Column(Integer, nullable=False)
    origin_network: Network = Column(Enum(Network), nullable=False)
    order: Mapped[Order] = relationship("Order")
    message: str = Column(String, nullable=False)
    created_at: datetime = Column(DateTime, nullable=False, server_default="clock_timestamp()")

    # Set order_id and origin_network as composite foreign key
    __table_args__ = (
        ForeignKeyConstraint(
            ["order_id", "origin_network"],
            ["orders.order_id", "orders.origin_network"]
        ),
    )
