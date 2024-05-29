from sqlalchemy.orm import Session

from src.models.error import Error


class ErrorDao:
    def __init__(self, db: Session):
        self.db = db

    def create_error(self, error: Error) -> Error:
        self.db.add(error)
        self.db.commit()
        return error
