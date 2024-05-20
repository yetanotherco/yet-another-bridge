import pytest
from sqlalchemy import text
from src.persistence.error_dao import ErrorDao
from src.models.network import Network
from src.models.error import Error
from tests.test_setup import setup_database, setup_function

# DEFAULT DATABASE SETUP
# ZKSYNC mainnet -> network = 324
# STARKNET mainnet -> network = 0x534e5f4d41494e
# INSERT INTO error (order_id, origin_network, message)
# VALUES
# (1, '324', 'Error message 1 for order 1 on ZKSYNC mainnet'),
# (2, '0x534e5f4d41494e', 'Error message 2 for order 2 on STARKNET mainnet'),
# (3, '324', 'Error message 3 for order 3 on ZKSYNC mainnet'),
# (4, '0x534e5f4d41494e', 'Error message 4 for order 4 on STARKNET mainnet');

def count_errors(db):
    return db.execute(text("SELECT COUNT(*) FROM error")).fetchone()[0]

def count_errors_by_network(db, network):
    return db.execute(text("SELECT COUNT(*) FROM error WHERE origin_network = :network"), {"network": network}).fetchone()[0]

def test_create_error(setup_database, setup_function):
    error_dao = ErrorDao(setup_database)
    network = Network.STARKNET
    new_error = error_dao.create_error(Error(order_id=4, origin_network=network, message="Error message 5 for order 4 on STARKNET mainnet"))
    assert new_error.id == 5
    assert new_error.order_id == 4
    assert new_error.origin_network == network
    assert new_error.message == "Error message 5 for order 4 on STARKNET mainnet"
    assert new_error.created_at is not None
    assert count_errors(setup_database) == 5
    assert count_errors_by_network(setup_database, network) == 3
