from enum import Enum


class OrderStatus(Enum):
    PENDING = "PENDING"
    PROCESSING = "PROCESSING"
    TRANSFERRING = "TRANSFERRING"
    FULFILLED = "FULFILLED"
    PROVING = "PROVING"
    PROVED = "PROVED"
    COMPLETED = "COMPLETED"
    DROPPED = "DROPPED"
