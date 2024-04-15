from web3.types import EventData


class ZksyncLog(EventData):
    """
    EventData web3 library class doesn't have a from_address field, so we need to extend it to store it
    """
    from_address: str
