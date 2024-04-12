from web3.types import EventData


# EventData web3 library class doesn't have a from_address field, so we need to extend it to store it
class ZksyncLog(EventData):
    from_address: str
