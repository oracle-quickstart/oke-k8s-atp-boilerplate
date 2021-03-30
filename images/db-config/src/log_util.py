# Copyright (c) 2021, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

import logging
import sys


def get_logger(name, log_level=None):
    logger = logging.getLogger(name)
    logger.addHandler(logging.StreamHandler(sys.stdout))
    if log_level is not None:
        log_level = getattr(logging, log_level.upper())
        logger.setLevel(log_level)
    return logger
