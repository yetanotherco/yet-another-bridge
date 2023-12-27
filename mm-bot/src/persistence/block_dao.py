from sqlalchemy.orm import Session

from models.block import Block


class BlockDao:
    def __init__(self, db: Session):
        self.db = db

    def get_latest_block(self) -> int:
        return (self.db.query(Block)
                .order_by(Block.id.desc())
                .first()
                .latest_block)

    def update_latest_block(self, latest_block: int):
        if self.get_latest_block() == latest_block:
            return
        block = Block(latest_block=latest_block)
        self.db.add(block)
        self.db.commit()
        return block
