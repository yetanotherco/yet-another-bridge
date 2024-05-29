from sqlalchemy.orm import Session

from src.models.block import Block
from src.models.network import Network


class BlockDao:
    def __init__(self, db: Session):
        self.db = db

    def get_latest_block(self, network: Network) -> int | None:
        latest_block = (self.db.query(Block)
                        .filter(Block.network == network)
                        .order_by(Block.id.desc())
                        .first())
        return latest_block.latest_block if latest_block else None

    def update_latest_block(self, latest_block: int, network: Network):
        if self.get_latest_block(network) == latest_block:
            return
        block = Block(latest_block=latest_block, network=network)
        self.db.add(block)
        self.db.commit()
        return block

    def create_block(self, latest_block: int, network: Network):
        block = Block(latest_block=latest_block, network=network)
        self.db.add(block)
        self.db.commit()
        return block
