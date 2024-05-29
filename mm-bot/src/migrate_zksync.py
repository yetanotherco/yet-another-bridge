import asyncio

from src.config.database_config import get_db
from src.models.order import Order
from src.persistence.order_dao import OrderDao


async def run():
    db = get_db()
    order_dao = OrderDao(db)
    orders = order_dao.get_orders(Order.order_id > 0)
    for order in orders:
        aux_hash = order.set_order_tx_hash.decode()
        aux = bytes.fromhex(aux_hash.replace("0x", "").zfill(64))
        order.set_order_tx_hash = aux
        order_dao.update_order(order)

asyncio.run(run())
