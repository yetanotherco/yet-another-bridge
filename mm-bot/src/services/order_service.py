from models.error import Error
from models.order import Order
from models.order_status import OrderStatus
from persistence.error_dao import ErrorDao
from persistence.order_dao import OrderDao


class OrderService:
    def __init__(self, order_dao: OrderDao, error_dao: ErrorDao):
        self.order_dao = order_dao
        self.error_dao = error_dao

    def create_order(self, order: Order) -> Order:
        """
        Create an order in the database

        :param order: the order to create
        """
        return self.order_dao.create_order(order)

    def get_order(self, order_id) -> Order | None:
        """
        Get an order from the database with the given order_id

        :param order_id: the order_id of the order to get
        """
        return self.order_dao.get_order(order_id)

    def get_incomplete_orders(self):
        """
        Get all orders that are not completed from the database
        An order is incomplete if it's not completed and not failed
        """
        return self.order_dao.get_incomplete_orders()

    def get_failed_orders(self):
        """
        Get all orders that are failed from the database
        """
        return self.order_dao.get_failed_orders()

    def already_exists(self, order_id) -> bool:
        """
        Check if an order with the given order_id already exists in the database

        :param order_id: the order_id of the order to check
        """
        return self.order_dao.already_exists(order_id)

    def set_order_processing(self, order: Order) -> Order:
        """
        Set the order status to "PROCESSING"

        :param order: the order to update
        """
        order.status = OrderStatus.PROCESSING.name
        return self.order_dao.update_order(order)

    def set_order_transferring(self, order: Order, tx_hash) -> Order:
        """
        Set the order status to "TRANSFERRING"

        :param order: the order to update
        :param tx_hash: the tx_hash of the ethereum transfer transaction
        """
        order.tx_hash = tx_hash
        order.status = OrderStatus.TRANSFERRING.name
        return self.order_dao.update_order(order)

    def set_order_fulfilled(self, order: Order) -> Order:
        """
        Set the order status to "FULFILLED"

        :param order: the order to update
        """
        order.status = OrderStatus.FULFILLED.name
        return self.order_dao.update_order(order)

    def set_order_proving_herodotus(self, order: Order, task_id, block, slot) -> Order:
        """
        Set the order status to "PROVING"

        :param order: the order to update
        :param task_id: the task_id of the herodotus task TODO define better
        :param block: the block of the herodotus task TODO define better
        :param slot: the slot of the herodotus task TODO define better
        """
        order.herodotus_task_id = task_id
        order.herodotus_block = block
        order.herodotus_slot = slot
        order.status = OrderStatus.PROVING.name
        return self.order_dao.update_order(order)

    def set_order_proving_ethereum(self, order: Order, tx_hash) -> Order:
        """
        Set the order status to "PROVING"

        :param order: the order to update
        :param tx_hash: the tx_hash of the ethereum withdraw transaction
        """
        order.eth_withdraw_tx_hash = tx_hash
        order.status = OrderStatus.PROVING.name
        return self.order_dao.update_order(order)

    def set_order_proved(self, order: Order) -> Order:
        """
        Set the order status to "PROVED"

        :param order: the order to update
        """
        order.status = OrderStatus.PROVED.name
        return self.order_dao.update_order(order)

    def set_order_completed(self, order: Order) -> Order:
        """
        Set the order status to "COMPLETED"
        """
        order.status = OrderStatus.COMPLETED.name
        return self.order_dao.update_order(order)

    def set_order_failed(self, order: Order, error_message: str) -> Order:
        """
        Set the order failed to True and create an error in the database.

        The order status is not changed, so the order can be retried

        :param order: the order to update
        :param error_message: the error message to store in the database
        """
        order = self.set_failed(order, True)
        error = Error(order_id=order.order_id, message=error_message)
        self.error_dao.create_error(error)
        return order

    def reset_failed_order(self, order: Order) -> Order:
        """
        Reset the failed order to False, so it can be retried

        :param order: the order to update
        """
        return self.set_failed(order, False)

    def set_failed(self, order: Order, failed: bool) -> Order:
        """
        Set the order failed to the given value

        :param order: the order to update
        :param failed: the value to set failed to
        """
        order.failed = failed
        return self.order_dao.update_order(order)
