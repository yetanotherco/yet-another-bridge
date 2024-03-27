from sqlalchemy.orm import Session

from models.block import Block
from models.network import Network


class BlockDao:
    def __init__(self, db: Session):
        self.db = db

    def get_latest_block(self, network: Network) -> int:
        return (self.db.query(Block)
                .filter(Block.network == network)
                .order_by(Block.id.desc())
                .first()
                .latest_block)

    def update_latest_block(self, latest_block: int, network: Network):
        if self.get_latest_block(network) == latest_block:
            return
        block = Block(latest_block=latest_block, network=network)
        self.db.add(block)
        self.db.commit()
        return block
