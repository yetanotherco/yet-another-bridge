import pytest
from sqlalchemy import text
from src.persistence.block_dao import BlockDao
from src.models.network import Network
from tests.test_setup import setup_database, setup_function

# DEFAULT DATABASE SETUP
# ZKSYNC mainnet -> network = 324
# STARKNET mainnet -> network = 0x534e5f4d41494e
# INSERT INTO block (network, latest_block)
# VALUES
# ('324', 1000),
# ('0x534e5f4d41494e', 2000),
# ('324', 3000),
# ('0x534e5f4d41494e', 4000);

def count_blocks(db):
    return db.execute(text("SELECT COUNT(*) FROM block")).fetchone()[0]

def count_blocks_by_network(db, network: Network):
    return db.execute(text("SELECT COUNT(*) FROM block WHERE network = :network"), {"network": network.value}).fetchone()[0]

def test_get_latest_block(setup_database, setup_function):
    block_dao = BlockDao(setup_database)
    network = Network.STARKNET
    latest_block = block_dao.get_latest_block(network)
    assert latest_block == 4000
    assert count_blocks(setup_database) == 4
    assert count_blocks_by_network(setup_database, network) == 2


def test_update_latest_block(setup_database, setup_function):
    block_dao = BlockDao(setup_database)
    network = Network.STARKNET
    latest_block = block_dao.update_latest_block(4000, network)
    assert latest_block is None
    assert count_blocks(setup_database) == 4
    assert count_blocks_by_network(setup_database, network) == 2
    latest_block = block_dao.update_latest_block(5000, network)
    assert latest_block.id == 5
    assert count_blocks(setup_database) == 5
    assert count_blocks_by_network(setup_database, network) == 3
    

def test_create_block(setup_database, setup_function):
    block_dao = BlockDao(setup_database)
    network = Network.STARKNET
    new_block = block_dao.create_block(5000, network)
    assert new_block.id == 5
    assert new_block.latest_block == 5000
    assert new_block.network == network
    assert new_block.created_at is not None
    assert count_blocks(setup_database) == 5
    assert count_blocks_by_network(setup_database, network) == 3
