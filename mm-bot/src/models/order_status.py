from enum import Enum


class OrderStatus(Enum):
    PENDING = "PENDING"
    PROCESSING = "PROCESSING"
    FULFILLED = "FULFILLED"
    PROVING = "PROVING"
    PROVED = "PROVED"
    COMPLETED = "COMPLETED"
