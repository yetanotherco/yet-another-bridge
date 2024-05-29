from typing import Type

from sqlalchemy import and_
from sqlalchemy.orm import Session

from src.models.order import Order
from src.models.order_status import OrderStatus


class OrderDao:
    def __init__(self, db: Session):
        self.db = db

    def create_order(self, order: Order) -> Order:
        if self.get_order(order.order_id, order.origin_network):
            raise Exception(f"Order  [{order.origin_network} ~ {order.order_id}] already exists")
        self.db.add(order)
        self.db.commit()
        return order

    def get_order(self, order_id, origin_network) -> Order | None:
        return (self.db.query(Order)
                .filter(and_(Order.order_id == order_id,
                             Order.origin_network == origin_network))
                .first())

    def get_orders(self, criteria) -> list[Type[Order]]:
        return (self.db.query(Order)
                .filter(criteria)
                .all())

    def get_incomplete_orders(self) -> list[Type[Order]]:
        """
        An order is incomplete if it's not completed or not DROPPED and not failed
        """
        criteria = and_(Order.status != OrderStatus.COMPLETED,
                        Order.status != OrderStatus.DROPPED,
                        Order.failed == False)
        return self.get_orders(criteria)

    def get_failed_orders(self) -> list[Type[Order]]:
        criteria = Order.failed
        return self.get_orders(criteria)

    def already_exists(self, order_id, origin_network) -> bool:
        return self.get_order(order_id, origin_network) is not None

    def update_order(self, order: Order) -> Order:
        self.db.commit()
        return order
