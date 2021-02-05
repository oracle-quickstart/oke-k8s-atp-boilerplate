import logging 
import sys


def get_logger(name, log_level=None):
    logger = logging.getLogger(name)
    logger.addHandler(logging.StreamHandler(sys.stdout))
    if log_level is not None:
        log_level = getattr(logging, log_level.upper())
        logger.setLevel(log_level)
    return logger
