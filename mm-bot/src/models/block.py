from datetime import datetime

from sqlalchemy import Column, Integer, DateTime, Enum

from src.config.database_config import Base
from src.models.network import Network


class Block(Base):
    __tablename__ = "block"
    id: int = Column(Integer, primary_key=True, nullable=False)
    network: Network = Column(Enum(Network), nullable=False)
    latest_block: int = Column(Integer, nullable=False)
    created_at: datetime = Column(DateTime, nullable=False, server_default="clock_timestamp()")

    def __str__(self):
        return f"latest_block:{self.latest_block}"
