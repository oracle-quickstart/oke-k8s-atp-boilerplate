# Copyright (c) 2021, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

import os

from log_util import get_logger


logger = get_logger(__name__, os.environ.get('LOG_LEVEL'))


class SSE(object):

    def __init__(self, clients, mngr):
        self.clients = clients
        self.mngr = mngr

    def subscribe(self, client_id):
        # create a queue for messages destined
        # to the client
        logger.info(f'subscribing client {client_id}')
        q = self.mngr.Queue(maxsize=10)
        self.clients[client_id] = q
        logger.debug(self.clients)
        return q

    def unsubscribe(self, client_id):
        if client_id in self.clients:
            logger.info(f'unsubscribing client {client_id}')
            del self.clients[client_id]


def format_sse(data: str, event=None) -> str:
    msg = f'data: {data}\n\n'
    if event is not None:
        msg = f'event: {event}\n{msg}'
    return msg
