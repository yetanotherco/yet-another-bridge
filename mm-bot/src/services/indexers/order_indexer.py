import logging
from abc import ABC

from models.network import Network
from models.order import Order


class OrderIndexer(ABC):

    def __init__(self):
        self.logger = logging.getLogger(__name__)

    async def get_orders(self, from_block, to_block) -> list[Order]:
        """
        Get orders from the escrow
        """
        pass

    async def get_new_orders(self) -> list[Order]:
        """
        Get new orders from the escrow
        Depending on the indexer implementation, it will use correct
        parameters to set from_block and to_block
        """
        pass

    async def get_network(self) -> Network:
        """
        Get the network of the indexer
        """
        pass
