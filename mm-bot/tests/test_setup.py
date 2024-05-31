import pytest
from sqlalchemy import text
from src.config.testing_config import SessionLocal, Base, Engine

@pytest.fixture(scope="module")
def setup_database():
    Base.metadata.create_all(bind=Engine)
    yield SessionLocal()
    Base.metadata.drop_all(bind=Engine)

@pytest.fixture(scope="function")
def setup_function():
    with Engine.connect() as conn:
        with conn.begin():
            with open("resources/test_inserts.sql", "r") as f:
                inserts_sql = f.read()
            conn.execute(text(inserts_sql))
    yield
    with Engine.connect() as conn:
        with conn.begin():
            with open("resources/test_teardown.sql", "r") as f:
                teardown_sql = f.read()
            conn.execute(text(teardown_sql))