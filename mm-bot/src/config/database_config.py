from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

from src.config import constants

engine = create_engine(
    f"postgresql://{constants.POSTGRES_USER}:{constants.POSTGRES_PASSWORD}@{constants.POSTGRES_HOST}:5432/{constants.POSTGRES_DATABASE}")

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    return SessionLocal()
