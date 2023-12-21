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
        return self.db.query(Order).filter(Order.order_id == order_id).first()

    def already_exists(self, order_id) -> bool:
        return self.get_order(order_id) is not None

    def update_order(self, order: Order, status: OrderStatus) -> Order:
        order.status = status.name
        self.db.commit()
        return order

    def set_order_herodotus_task_id(self, order: Order, herodotus_task_id: str) -> Order:
        order.herodotus_task_id = herodotus_task_id
        self.db.commit()
        return order

