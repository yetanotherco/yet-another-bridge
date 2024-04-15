from dataclasses import dataclass
from typing import Optional, List, Union, cast

from marshmallow import fields, post_load
from starknet_py.net.client_models import Hash, Tag, EventsChunk, Event
from starknet_py.net.full_node_client import FullNodeClient, _get_raw_block_identifier, _to_rpc_felt
from starknet_py.net.schemas.rpc import EventSchema, EventsChunkSchema

EXCLUDE = "exclude"


@dataclass
class MmEvent(Event):
    tx_hash: str
    from_address: str
    block_number: int


class MmEventSchema(EventSchema):
    tx_hash = fields.String(data_key="transaction_hash", required=True)
    block_number = fields.Integer(data_key="block_number", load_default=None)

    @post_load
    def make_dataclass(self, data, **kwargs) -> Event:
        return MmEvent(**data)


@dataclass
class MmEventsChunk(EventsChunk):
    events: List[MmEvent]
    continuation_token: Optional[str]


class MmEventsChunkSchema(EventsChunkSchema):
    events = fields.List(
        fields.Nested(MmEventSchema(unknown=EXCLUDE)),
        data_key="events",
        required=True,
    )
    continuation_token = fields.String(data_key="continuation_token", load_default=None)

    @post_load
    def make_dataclass(self, data, **kwargs):
        return EventsChunk(**data)


class MmFullNodeClient(FullNodeClient):

    async def get_events(self, address: Optional[Hash] = None, keys: Optional[List[List[Hash]]] = None, *,
                         from_block_number: Optional[Union[int, Tag]] = None,
                         from_block_hash: Optional[Union[Hash, Tag]] = None,
                         to_block_number: Optional[Union[int, Tag]] = None,
                         to_block_hash: Optional[Union[Hash, Tag]] = None, follow_continuation_token: bool = False,
                         continuation_token: Optional[str] = None, chunk_size: int = 1) -> MmEventsChunk:
        if chunk_size <= 0:
            raise ValueError("Argument chunk_size must be greater than 0.")

        if keys is None:
            keys = []
        if address is not None:
            address = _to_rpc_felt(address)
        if from_block_number is None and from_block_hash is None:
            from_block_number = 0

        from_block = _get_raw_block_identifier(from_block_hash, from_block_number)
        to_block = _get_raw_block_identifier(to_block_hash, to_block_number)
        keys = [[_to_rpc_felt(key) for key in inner_list] for inner_list in keys]

        events_list = []
        while True:
            events, continuation_token = await self._get_events_chunk(
                from_block=from_block,
                to_block=to_block,
                address=address,
                keys=keys,
                chunk_size=chunk_size,
                continuation_token=continuation_token,
            )
            events_list.extend(events)
            if not follow_continuation_token or continuation_token is None:
                break

        events_response = cast(
            MmEventsChunk,
            MmEventsChunkSchema().load(
                {"events": events_list, "continuation_token": continuation_token}
            ),
        )

        return events_response
