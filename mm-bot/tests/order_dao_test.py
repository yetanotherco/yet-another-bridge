import pytest
from sqlalchemy import text
from src.persistence.order_dao import OrderDao
from src.models.network import Network
from src.models.order import Order
from src.models.order_status import OrderStatus
from tests.test_setup import setup_database, setup_function

# DEFAULT DATABASE SETUP
# ZKSYNC mainnet -> network = 324
# STARKNET mainnet -> network = 0x534e5f4d41494e
# INSERT INTO orders (order_id, origin_network, from_address, recipient_address, amount, fee, status, failed, set_order_tx_hash)
# VALUES
# (1, '324', '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef', '0x1234567890123456789012345678901234567890', 1000, 10, 'PENDING', FALSE, '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef'),
# (2, '0x534e5f4d41494e', '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef', '0x2234567890123456789012345678901234567890', 2000, 20, 'COMPLETED', FALSE, '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef'),
# (3, '324', '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef', '0x3234567890123456789012345678901234567890', 3000, 30, 'DROPPED', TRUE, '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef'),
# (4, '0x534e5f4d41494e', '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef', '0x4234567890123456789012345678901234567890', 4000, 40, 'PENDING', FALSE, '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef');

def count_orders(db):
    return db.execute(text("SELECT COUNT(*) FROM orders")).fetchone()[0]

def count_orders_by_network(db, network):
    return db.execute(text("SELECT COUNT(*) FROM orders WHERE origin_network = :network"), {"network": network}).fetchone()[0]

def test_create_order(setup_database, setup_function):
    order_dao = OrderDao(setup_database)
    network = Network.STARKNET
    new_order = order_dao.create_order(Order(order_id=5, origin_network=network, from_address="0x5234567890123456789012345678901234567890", recipient_address="0x5234567890123456789012345678901234567890", amount=5000, fee=50, set_order_tx_hash="0x5234567890123456789012345678901234567890"))
    assert new_order.order_id == 5
    assert new_order.origin_network == network
    assert new_order.from_address == "0x5234567890123456789012345678901234567890"
    assert new_order.recipient_address == "0x5234567890123456789012345678901234567890"
    assert new_order.amount == 5000
    assert new_order.fee == 50
    assert new_order.set_order_tx_hash == "0x5234567890123456789012345678901234567890"
    assert new_order.created_at is not None
    assert count_orders(setup_database) == 5
    assert count_orders_by_network(setup_database, network) == 3

def test_get_order(setup_database, setup_function):
    order_dao = OrderDao(setup_database)
    network = Network.STARKNET
    order = order_dao.get_order(4, network)
    assert order.order_id == 4
    assert order.origin_network == network
    assert order.from_address == "0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef"
    assert order.recipient_address == "0x5234567890123456789012345678901234567890"
    assert order.amount == 4000
    assert order.fee == 40
    assert order.status.value == "PENDING"
    assert order.failed == False
    assert order.set_order_tx_hash == "0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef"
    assert order.created_at is not None
    assert count_orders(setup_database) == 4
    assert count_orders_by_network(setup_database, network) == 2

def test_get_orders(setup_database, setup_function):
    order_dao = OrderDao(setup_database)
    orders = order_dao.get_orders(Order.order_id > 0)
    assert len(orders) == 4
    assert count_orders(setup_database) == 4

def test_get_incomplete_orders(setup_database, setup_function):
    order_dao = OrderDao(setup_database)
    orders = order_dao.get_incomplete_orders()
    assert len(orders) == 2
    assert count_orders(setup_database) == 4

def test_get_failed_orders(setup_database, setup_function):
    order_dao = OrderDao(setup_database)
    orders = order_dao.get_failed_orders()
    assert len(orders) == 1
    assert count_orders(setup_database) == 4

def test_already_exists(setup_database, setup_function):
    order_dao = OrderDao(setup_database)
    network = Network.STARKNET
    assert order_dao.already_exists(4, network) == True
    assert order_dao.already_exists(5, network) == False

def test_update_order(setup_database, setup_function):
    order_dao = OrderDao(setup_database)
    network = Network.STARKNET
    order = order_dao.get_order(4, network)
    order.status = OrderStatus.COMPLETED
    updated_order = order_dao.update_order(order)
    assert updated_order.status.value == "COMPLETED"
    assert count_orders(setup_database) == 4
    assert count_orders_by_network(setup_database, network) == 2
