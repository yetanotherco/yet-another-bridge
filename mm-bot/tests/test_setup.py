import pytest
from sqlalchemy import text
from src.config.testing_config import SessionLocal, Engine
from src.config.database_config import Base
from src.models import block, error, order

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
            statements = inserts_sql.split(";")
            for statement in statements:
                if statement.strip():
                    result = conn.execute(text(statement))
    yield
    with Engine.connect() as conn:
        with conn.begin():
            with open("resources/test_teardown.sql", "r") as f:
                teardown_sql = f.read()
            statements = teardown_sql.split(";")
            for statement in statements:
                if statement.strip():
                    result = conn.execute(text(statement))
            