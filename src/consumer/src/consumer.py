import logging
import ssl
import sys
from os import environ
from time import sleep

import cx_Oracle
from kafka import KafkaConsumer


logger = logging.getLogger('kafka')
logger.addHandler(logging.StreamHandler(sys.stdout))
LOG_LEVEL = environ.get('LOG_LEVEL')

if LOG_LEVEL is not None:
    log_level = getattr(logging, LOG_LEVEL.upper())
    logger.setLevel(log_level)


def get_consumer():
    sasl_mechanism = 'PLAIN'
    security_protocol = 'SASL_SSL'

    # Create a new context using system defaults, disable all but TLS1.2
    context = ssl.create_default_context()
    context.options &= ssl.OP_NO_TLSv1
    context.options &= ssl.OP_NO_TLSv1_1
    kafka_brokers = environ.get('KAFKA_BROKERS')

    # The service binding secret gives an endpoint
    # with https:// prefix but we need only the hostname:port
    if "https://" in kafka_brokers:
        kafka_brokers = kafka_brokers.replace("https://", "")

    consumer = KafkaConsumer(
        environ.get('TOPIC'),
        bootstrap_servers=kafka_brokers,
        sasl_plain_username=environ.get('KAFKA_USERNAME'),  # tenancy/username/streampoolid
        sasl_plain_password=environ.get('KAFKA_PASSWORD'),  # auth token
        security_protocol=security_protocol,
        ssl_context=context,
        sasl_mechanism=sasl_mechanism,
        # api_version = (0,10),
        # required or it will error:
        fetch_max_bytes=1024 * 1024,  # 1MB
        auto_offset_reset='earliest',
        enable_auto_commit=True,
        group_id='my-group',
        value_deserializer=lambda x: x.decode('utf-8')
        )
    return consumer


def atp_setup(connection):

    cursor = connection.cursor()
    cursor.execute("SELECT * FROM dba_tables WHERE table_name = 'MESSAGES' and owner = 'DEMODATA'")
    rows = cursor.fetchall()

    if len(rows) == 0:
        cursor.execute("""CREATE USER demodata
        IDENTIFIED BY u8888vIAbt2CvTO4Kzyw
        QUOTA UNLIMITED ON DATA""")
        cursor.execute("""
        CREATE TABLE demodata.messages (
            id RAW(16) DEFAULT SYS_GUID() NOT NULL PRIMARY KEY,
            rcvd_at_ts TIMESTAMP WITH TIME ZONE,
            msg CLOB CONSTRAINT ensure_json CHECK (msg IS JSON)
        )
        """)
        connection.commit()


def post_to_atp(connection, msg):

    cursor = connection.cursor()
    cursor.execute("""
    INSERT INTO demodata.messages (rcvd_at_ts, msg)
    VALUES (
        TO_TIMESTAMP_TZ(CURRENT_TIMESTAMP, 'DD-MON-RR HH.MI.SSXFF PM TZH:TZM'),
        :msg
    )
    """, msg=msg.value)
    connection.commit()


if __name__ == '__main__':

    print("connecting to stream...")
    consumer = get_consumer()
    print("ready to receive")

    username = environ.get('DB_ADMIN_USER')
    password = environ.get('DB_ADMIN_PWD')
    tns_name = environ.get('TNS_NAME')
    cx_Oracle.init_oracle_client(config_dir="/instantclient_21_1/network/admin")
    logger.debug(environ.get('TNS_ADMIN'))

    try:
        with cx_Oracle.connect(username, password, tns_name, encoding="UTF-8") as connection:

            print("DB connection OK")
            # If table does not exists, create it
            atp_setup(connection)

            print("DB setup OK")

            for msg in consumer:
                post_to_atp(connection, msg)
                print(msg)
    except Exception as e:
        print(str(e))
        sleep(3600)
