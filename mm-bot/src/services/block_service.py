import logging

from src.models.network import Network
from src.persistence.block_dao import BlockDao


class BlockService:
    def __init__(self, block_dao: BlockDao):
        self.logger = logging.getLogger(__name__)
        self.block_dao = block_dao

    def init_blocks(self):
        """
        Insert the first block of the zkSync and Starknet networks
        """
        if not self.block_dao.get_latest_block(Network.ZKSYNC):
            self.logger.info("[+] Inserting first block for zkSync")
            self.create_block(0, Network.ZKSYNC)
        if not self.block_dao.get_latest_block(Network.STARKNET):
            self.logger.info("[+] Inserting first block for Starknet")
            self.create_block(0, Network.STARKNET)

    def create_block(self, latest_block: int, network: Network):
        """
        Insert a block in the database

        :param latest_block: the latest block to insert
        :param network: the network of the block
        """
        return self.block_dao.create_block(latest_block, network)
