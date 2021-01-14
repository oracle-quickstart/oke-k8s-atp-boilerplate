from kafka import KafkaProducer
from kafka.errors import KafkaError
import ssl
import sys
import argparse
from os import environ
from random import random
from math import cos
from time import sleep
import json

import logging

logger = logging.getLogger('kafka')
logger.addHandler(logging.StreamHandler(sys.stdout))
LOG_LEVEL = environ.get('LOG_LEVEL')
if LOG_LEVEL is not None:
    log_level = getattr(logging, LOG_LEVEL.upper())
    logger.setLevel(log_level)

def get_producer():

    # Create a new context using system defaults, disable all but TLS1.2
    context = ssl.create_default_context()
    # context.options &= ssl.OP_NO_TLSv1
    # context.options &= ssl.OP_NO_TLSv1_1

    producer = KafkaProducer(bootstrap_servers = environ.get('KAFKA_BROKERS'),
                         sasl_plain_username = environ.get('KAFKA_USERNAME'),  # tenancy/username/streampoolid
                         sasl_plain_password = environ.get('KAFKA_PASSWORD'),  # auth token
                         security_protocol = 'SASL_SSL',
                         ssl_context = context,
                         sasl_mechanism = 'PLAIN',
                         max_request_size = 1024 * 1024,
                         retries=5)

    return producer


def send_message(producer, key, message):

    try:
        print(message.encode('utf-8'))
        return producer.send(environ.get('TOPIC'), key="0".encode('utf-8'), value=message.encode('utf-8'))
    except:
        print("Unexpected error:", sys.exc_info()[0])
        raise


if __name__ == '__main__':

    print("connecting...")
    producer = get_producer()

    print(f"connected: {producer.bootstrap_connected()}")

    print("ready to send")
    variance = 0
    i = 0
    while True:
        val = cos(i / 100.0) + variance
        result = send_message(producer, str(i), json.dumps({"value": val, "index": i}))
        i += 1
        variance += (random() - 0.5) / 10.0
        sleep(1)
