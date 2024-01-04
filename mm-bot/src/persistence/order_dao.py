from typing import Type

from sqlalchemy import and_
from sqlalchemy.orm import Session

from models.order import Order
from models.order_status import OrderStatus


class OrderDao:
    def __init__(self, db: Session):
        self.db = db

    def create_order(self, order: Order) -> Order:
        if self.get_order(order.order_id):
            raise Exception(f"Order with order_id {order.order_id} already exists")
        self.db.add(order)
        self.db.commit()
        return order

    def get_order(self, order_id) -> Order | None:
        return (self.db.query(Order)
                .filter(Order.order_id == order_id)
                .first())

    def get_orders(self, criteria) -> list[Type[Order]]:
        return (self.db.query(Order)
                .filter(criteria)
                .all())

    def get_incomplete_orders(self) -> list[Type[Order]]:
        """
        An order is incomplete if it's not completed and not failed
        """
        criteria = and_(Order.status != OrderStatus.COMPLETED,
                        Order.failed == False)
        return self.get_orders(criteria)

    def get_failed_orders(self) -> list[Type[Order]]:
        criteria = Order.failed
        return self.get_orders(criteria)

    def already_exists(self, order_id) -> bool:
        return self.get_order(order_id) is not None

    def update_order(self, order: Order) -> Order:
        self.db.commit()
        return order
