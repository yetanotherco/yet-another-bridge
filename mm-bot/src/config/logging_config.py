import asyncio
import logging
from logging.handlers import TimedRotatingFileHandler
import sys
from config import constants


def setup_logger():
    logger = logging.getLogger()
    logger.setLevel(logging.DEBUG)

    # Formatter for log messages
    log_format = "%(asctime)s %(levelname)6s - [%(threadName)15s] [%(taskName)15s] : %(message)s"
    formatter = logging.Formatter(log_format, datefmt="%Y-%m-%dT%H:%M:%S")

    # Add handlers based on the environment
    if in_production():
        handler = get_production_handler(formatter)
    else:
        handler = get_development_handler(formatter)
    handler.addFilter(AsyncioFilter())
    logger.addHandler(handler)


def in_production():
    return constants.ENVIRONMENT == 'prod'


# Console Handler for development
def get_development_handler(formatter):
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(constants.LOGGING_LEVEL)
    console_handler.setFormatter(formatter)
    return console_handler


# File Handler for production with daily rotation
def get_production_handler(formatter):
    file_handler = TimedRotatingFileHandler(
        filename=f"{constants.LOGGING_DIRECTORY}/mm-bot.log",
        when="midnight",
        interval=1,
        backupCount=7,  # Keep up to 7 old log files
        encoding="utf-8"
    )
    file_handler.setLevel(constants.LOGGING_LEVEL)
    file_handler.setFormatter(formatter)
    return file_handler


class AsyncioFilter(logging.Filter):
    """
    This is a filter which injects contextual information into the log.
    """
    def filter(self, record):
        try:
            record.taskName = asyncio.current_task().get_name()
        except Exception:
            record.taskName = "Main"
        return True
