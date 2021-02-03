import json
import logging
import socket
import ssl
import sys
from datetime import datetime
from math import cos
from os import environ
from random import randint, random
from time import sleep

from kafka import KafkaProducer


logger = logging.getLogger('kafka')
logger.addHandler(logging.StreamHandler(sys.stdout))
LOG_LEVEL = environ.get('LOG_LEVEL')
if LOG_LEVEL is not None:
    log_level = getattr(logging, LOG_LEVEL.upper())
    logger.setLevel(log_level)

hostname = socket.gethostname()
sleep_time = float(environ.get('SLEEP_TIME', 0.2))

def get_producer():
    '''Initialize the connection to the streaming service (i.e. Kafka broker)
    and returns a producer object
    '''
    # Create a new context using system defaults, disable all but TLS1.2
    context = ssl.create_default_context()
    context.options &= ssl.OP_NO_TLSv1
    context.options &= ssl.OP_NO_TLSv1_1
    message_endpoint = environ.get('messageEndpoint')
    kafka_brokers = f"{message_endpoint}:9092"
    username = environ.get('USERNAME')
    stream_pool_id = environ.get('streamPoolId')
    kafka_username = f"{username}/{stream_pool_id}"
    kafka_password = environ.get('KAFKA_PASSWORD')

    # the endpoint from the OCI Service broker includes the 'https://' scheme
    # and needs to be removed.
    if "https://" in kafka_brokers:
        kafka_brokers = kafka_brokers.replace("https://", "")

    # create a producer
    producer = KafkaProducer(
        bootstrap_servers=kafka_brokers,
        sasl_plain_username=kafka_username,  # tenancy/username/streampoolid
        sasl_plain_password=kafka_password,  # auth token
        security_protocol='SASL_SSL',
        ssl_context=context,
        sasl_mechanism='PLAIN',
        max_request_size=1024 * 1024,  # required to match the max Write throughput of the service
        retries=5)
    return producer


def send_message(producer, key, message):
    """Send a message to the streaming service
    producer: the producer connection to use
    key: a key to partition the data
    message: the message payload (as a string)
    """
    try:
        print(message.encode('utf-8'))
        return producer.send(
            environ.get('TOPIC'),
            key=key.encode('utf-8'),
            value=message.encode('utf-8'))
    except Exception as e:
        print("Unexpected error:", sys.exc_info()[0])
        raise e


if __name__ == '__main__':

    print("connecting...")
    producer = get_producer()
    print(f"connected: {producer.bootstrap_connected()}")

    print("ready to send")
    variance = 0
    i = 0
    while True:
        val = cos(i / 10.0) + variance
        result = send_message(producer, str(randint(0, 4)), json.dumps({
            "value": val,
            "index": i,
            "ts": datetime.now().timestamp(),
            "hostname": hostname
            }))
        i += 1
        variance += (random() - 0.5) / 10.0
        sleep(sleep_time)
