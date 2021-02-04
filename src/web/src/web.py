import json
import uuid
import flask
import os
import multiprocessing
from datafetch import odatafetch
from time import sleep

# multiprocessing patch
import mp_patch
mp_patch.apply()

from sse import SSE

# this line fixes issues with ptvsd debugger
multiprocessing.set_start_method('spawn', True)

# Serve the static content out of the 'static' folder
app = flask.Flask(__name__, static_folder="static")

# Global cache header 
@app.after_request
def apply_caching(response):
    response.headers["Cache-Control"] = "no-cache"
    response.headers["Pragma"] = "no-cache"
    return response

# index route
@app.route("/", methods=['GET'])
def static_proxy():
    return app.send_static_file("index.html")

# Server Sent Event route, server-push the data to the clients
@app.route("/data", methods=['GET'])
def data_stream():
    def stream():
        # on connection, subscribe to message queue with uuid
        client_id = str(uuid.uuid4())
        try:
            messages = broadcaster.subscribe(client_id)  # returns a multiprocessing.Queue
            while True:
                # blocks as long as queue is empty
                yield messages.get()  
        finally:
            # on disconnect, unsubscribe this client
            broadcaster.unsubscribe(client_id)

    # serve an 'event-stream', i.e. a long polling request
    return flask.Response(stream(), mimetype='text/event-stream')


if __name__ == '__main__':
    try:
        # define an object manager from multiprocessing, 
        # as our data fetching code runs on a separate process
        mgr = multiprocessing.Manager()
        # the clients dict keeps track of connected clients.
        clients = mgr.dict()
        # initialize the SSE broadcaster
        broadcaster = SSE(clients, mgr)

        # run the data call as a separate process, pass it the shared client list
        thread1 = multiprocessing.Process(target=odatafetch, args=(clients,))
        thread1.start()

        # run the actual web server
        context = ('./src/server.cert', './src/server.key')
        app.run(port=8000, host=os.environ.get("HOST", "127.0.0.1"), ssl_context=context)

    except Exception as e:
        print(str(e))
