import logging
from logging.handlers import TimedRotatingFileHandler
import sys
import constants


def setup_logger():
    logger = logging.getLogger()
    logger.setLevel(logging.DEBUG)

    # Formatter for log messages
    log_format = "%(asctime)s - [%(levelname)s] - %(message)s"
    formatter = logging.Formatter(log_format, datefmt="%Y-%m-%dT%H:%M:%S")

    # Console Handler for development
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(constants.LOGGING_LEVEL)
    console_handler.setFormatter(formatter)

    # File Handler for production with daily rotation
    file_handler = TimedRotatingFileHandler(
        filename=f"{constants.LOGGING_DIR}/mm-bot.log",
        when="midnight",
        interval=1,
        backupCount=7,  # Keep up to 7 old log files
        encoding="utf-8"
    )
    file_handler.setLevel(constants.LOGGING_LEVEL)
    file_handler.setFormatter(formatter)

    # Add handlers based on the environment
    if in_production():
        logger.addHandler(file_handler)
    else:
        logger.addHandler(console_handler)


def in_production():
    return constants.ENVIRONMENT == 'prod'
