import math
import json
from multiprocessing import Queue 
from sse import format_sse
from time import sleep
import cx_Oracle
from os import environ

def datafetch(clients):
    i = 0
    while True:
        msg_obj = {'date': i, 'value': math.cos(50 * i / 180), 'host': i % 2}
        msg = format_sse(data=json.dumps(msg_obj))
        for k,v in clients.items():
            try:
                v.put(msg)
            except Queue.Full as e:
                print(str(e))
        i += 1
        sleep(0.1)

def odatafetch(clients):
    username = environ.get('DB_USER')
    password = environ.get('DB_PWD')
    tns_name = environ.get('TNS_NAME')
    cx_Oracle.init_oracle_client(config_dir="/instantclient_21_1/network/admin")

    try:
        with cx_Oracle.connect(username, password, tns_name, encoding="UTF-8", events=True) as connection:
            print("DB connection OK")

            reg_id = None

            def callback(cqn_message):
                for table in cqn_message.tables:
                    if table.name == 'DEMODATA.MESSAGES':
                        for row in table.rows:
                            # we got a row added. Grab the rowid and send the data to our clients
                            cursor = connection.cursor()
                            cursor.execute("""
                            SELECT ROWID, m.msg.ts ts, m.msg.value value, m.msg.hostname host 
                            FROM demodata.messages m
                            WHERE ROWID = :rid""", rid=row.rowid)
                            rows = cursor.fetchall()
                            for d in rows:
                                msg_obj = {'date': float(d[1]), 'value': float(d[2]), 'host': d[3]}
                                msg = format_sse(data=json.dumps(msg_obj))
                                # post to all client queues
                                for k,v in clients.items():
                                    try:
                                        v.put(msg)
                                    except queue.Full as e:
                                        print(str(e))




            # Subscribe to Change Query Notifications, to get data updates
            print("subscribing")
            subscription = connection.subscribe(
                namespace=cx_Oracle.SUBSCR_NAMESPACE_DBCHANGE,
                operations=cx_Oracle.OPCODE_INSERT,
                qos = cx_Oracle.SUBSCR_QOS_BEST_EFFORT | cx_Oracle.SUBSCR_QOS_ROWIDS,
                callback=callback,
                clientInitiated=True
            )
            # Register query to 
            print("registering query")
            reg_id = subscription.registerquery("""SELECT rcvd_at_ts FROM demodata.messages""")
            while True:
                sleep(5)

    except Exception as e:
        print(str(e))
        sleep(3600)
