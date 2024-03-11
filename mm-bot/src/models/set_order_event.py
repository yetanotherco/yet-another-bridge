import asyncio

from models.network import Network
from services import ethereum


class SetOrderEvent:

    def __init__(self,
                 order_id,
                 origin_network,
                 set_order_tx_hash,
                 recipient_address,
                 amount,
                 fee,
                 block_number,
                 is_used=False):
        self.order_id = order_id
        self.origin_network = origin_network
        self.set_order_tx_hash = set_order_tx_hash
        self.recipient_address = recipient_address
        self.amount = amount
        self.fee = fee
        self.block_number = block_number
        self.is_used = is_used

    @staticmethod
    async def from_starknet(event):
        """
        event = {
            "tx_hash": "0x
            "block_number": 0,
            "data": [0, 0, 0, 0, 0, 0, 0]
        }
        """
        order_id = SetOrderEvent.parse_u256_from_double_u128(event.data[0], event.data[1])
        # event.tx_hash is a string. We need to store it as bytes.
        # Complete the hash with zeroes because fromhex needs pair number of elements
        set_order_tx_hash = bytes.fromhex(event.tx_hash.replace("0x", "").zfill(64))
        recipient_address = hex(event.data[2])
        amount = SetOrderEvent.parse_u256_from_double_u128(event.data[3], event.data[4])
        fee = SetOrderEvent.parse_u256_from_double_u128(event.data[5], event.data[6])
        is_used = await asyncio.to_thread(ethereum.get_is_used_order, order_id, recipient_address, amount)
        return SetOrderEvent(
            order_id=order_id,
            origin_network=Network.STARKNET,
            set_order_tx_hash=set_order_tx_hash,
            recipient_address=recipient_address,
            amount=amount,
            fee=fee,
            block_number=event.block_number,
            is_used=is_used
        )

    @staticmethod
    async def from_zksync(log):
        """
        log = {
            "transactionHash": "0x",
            "blockNumber": 0,
            "args": {
                "order_id": 0,
                "recipient_address": "0x",
                "amount": 0,
                "fee": 0
            }
        }
        transactionHash: HexBytes
        recipient_address: str
        """
        order_id = log.args.order_id
        set_order_tx_hash = log.transactionHash
        recipient_address = log.args.recipient_address
        amount = log.args.amount
        fee = log.args.fee
        is_used = await asyncio.to_thread(ethereum.get_is_used_order, order_id, recipient_address, amount)  # TODO change to new contract signature
        return SetOrderEvent(
            order_id=order_id,
            origin_network=Network.ZKSYNC,
            set_order_tx_hash=set_order_tx_hash,
            recipient_address=recipient_address,
            amount=amount,
            fee=fee,
            block_number=log.blockNumber,
            is_used=is_used
        )

    @staticmethod
    def parse_u256_from_double_u128(low, high) -> int:
        return high << 128 | low

    def __str__(self):
        return f"Order: {self.order_id} - Origin: {self.origin_network} - Amount: {self.amount} - Fee: {self.fee} - " \
               f"Recipient: {self.recipient_address} - Is used: {self.is_used} - Block: {self.block_number}"

    def __repr__(self):
        return self.__str__()
