from datetime import datetime

from sqlalchemy import Column, Integer, DateTime

from config.database_config import Base


class Block(Base):
    __tablename__ = "block"
    id: int = Column(Integer, primary_key=True, nullable=False)
    latest_block: int = Column(Integer, nullable=False)
    created_at: datetime = Column(DateTime, nullable=False, server_default="clock_timestamp()")

    def __str__(self):
        return f"latest_block:{self.latest_block}"
