# server side events handling
from multiprocessing import Queue 


class SSE(object):

    def __init__(self, clients, mngr):
        self.clients = clients
        self.mngr = mngr

    def subscribe(self, client_id):
        # create a queue for messages destined 
        # to the client
        print(f'subscribing client {client_id}')
        q = self.mngr.Queue(maxsize=10)
        self.clients[client_id] = q
        # print(self.clients)
        return q

    def unsubscribe(self, client_id):
        if client_id in self.clients:
            del self.clients[client_id]

    # def publish(self, msg):
    #     print(self.clients)
    #     for k in self.clients.keys():
    #         try:
    #             self.clients.get(k).put_nowait(msg)
    #         except queue.Full:
    #             pass


def format_sse(data: str, event=None) -> str:
    msg = f'data: {data}\n\n'
    if event is not None:
        msg = f'event: {event}\n{msg}'
    return msg