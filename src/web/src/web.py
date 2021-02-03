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


app = flask.Flask(__name__, static_folder="static")


@app.after_request
def apply_caching(response):
    response.headers["Cache-Control"] = "no-cache"
    response.headers["Pragma"] = "no-cache"
    return response

@app.route("/", methods=['GET'])
def static_proxy():
    return app.send_static_file("index.html")

@app.route("/data", methods=['GET'])
def data_stream():
    def stream():
        # on connection, subscribe to message queue with uuid
        client_id = str(uuid.uuid4())
        try:
            messages = broadcaster.subscribe(client_id)  # returns a queue.Queue
            while True:
                # blocks as long as queue is empty
                yield messages.get()  
        finally:
            # on disconnect, unsubscribe
            broadcaster.unsubscribe(client_id)

    return flask.Response(stream(), mimetype='text/event-stream')


if __name__ == '__main__':

    try:
        mgr = multiprocessing.Manager()
        clients = mgr.dict()
        broadcaster = SSE(clients, mgr)

        # run the data call in the background.
        thread1 = multiprocessing.Process(target=odatafetch, args=(clients,))
        thread1.start()

        # run the server
        context = ('./src/server.cert', './src/server.key')
        app.run(port=8000, host=os.environ.get("HOST", "127.0.0.1"), ssl_context=context)


    except Exception as e:
        print(str(e))
        sleep(3600)