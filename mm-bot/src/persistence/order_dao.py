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

    def already_exists(self, order_id) -> bool:
        return self.get_order(order_id) is not None

    def update_order(self, order: Order, status: OrderStatus) -> Order:
        order.status = status.name
        self.db.commit()
        return order

    def set_order_processing(self, order: Order) -> Order:
        return self.update_order(order, OrderStatus.PROCESSING)

    def set_order_transferring(self, order: Order, tx_hash) -> Order:
        order.tx_hash = tx_hash
        order.status = OrderStatus.TRANSFERRING.name
        self.db.commit()
        return order

    def set_order_fulfilled(self, order: Order) -> Order:
        return self.update_order(order, OrderStatus.FULFILLED)

    def set_order_proving_herodotus(self, order: Order, task_id, block, slot) -> Order:
        order.herodotus_task_id = task_id
        order.herodotus_block = block
        order.herodotus_slot = slot
        order.status = OrderStatus.PROVING.name
        self.db.commit()
        return order

    def set_order_proving_ethereum(self, order: Order, tx_hash) -> Order:
        order.eth_withdraw_tx_hash = tx_hash
        order.status = OrderStatus.PROVING.name
        self.db.commit()
        return order

    def set_order_proved(self, order: Order) -> Order:
        return self.update_order(order, OrderStatus.PROVED)

    def set_order_completed(self, order: Order) -> Order:
        return self.update_order(order, OrderStatus.COMPLETED)

    def set_order_no_balance(self, order: Order) -> Order:
        return self.update_order(order, OrderStatus.NO_BALANCE)

    """
    An order is incomplete if it's not completed, not failed or has balance
    An order in NO_BALANCE state is considered COMPLETED and will be re-processed in the next iteration
        when the balance is enough
    """

    def get_incomplete_orders(self):
        return (self.db.query(Order)
                .filter(and_(Order.status != OrderStatus.COMPLETED,
                             Order.status != OrderStatus.FAILED,
                             Order.status != OrderStatus.NO_BALANCE))
                .all())

    def get_no_balance_orders(self):
        return (self.db.query(Order)
                .filter(Order.status == OrderStatus.NO_BALANCE)
                .all())
