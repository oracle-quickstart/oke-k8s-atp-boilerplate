# Copyright (c) 2021, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

import json
import socket
import ssl
import sys
from datetime import datetime
from math import cos
from os import environ
from random import random
from time import sleep

from kafka import KafkaProducer

from log_util import get_logger


# Override kafka logger
kafka_logger = get_logger('kafka', environ.get('KAFKA_LOG_LEVEL'))
# set local logger
logger = get_logger(__name__, environ.get('LOG_LEVEL'))
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
        logger.debug(message.encode('utf-8'))
        return producer.send(
            environ.get('TOPIC'),
            key=key.encode('utf-8'),
            value=message.encode('utf-8'))
    except Exception as e:
        logger.error("Unexpected error:", sys.exc_info()[0])
        raise e


if __name__ == '__main__':

    logger.info("connecting...")
    try:
        producer = get_producer()
    except Exception as e:
        logger.error(str(e))
        if environ.get('KAFKA_LOG_LEVEL').lower() == 'debug':
            sleep(3600)
    logger.info(f"connected: {producer.bootstrap_connected()}")

    logger.info("ready to send")
    variance = 0
    i = 0
    while True:
        val = cos(i / 10.0) + variance
        result = send_message(producer, hostname, json.dumps({
            "value": val,
            "index": i,
            "ts": datetime.now().timestamp(),
            "hostname": hostname
            }))
        i += 1
        variance += (random() - 0.5) / 10.0
        sleep(sleep_time)
