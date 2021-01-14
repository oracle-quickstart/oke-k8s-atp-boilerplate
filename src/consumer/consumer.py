from kafka import KafkaConsumer
from kafka.errors import KafkaError
import ssl
import sys
import argparse
from os import environ
from random import random
from math import cos
from time import sleep

def get_consumer():
    sasl_mechanism = 'PLAIN'
    security_protocol = 'SASL_SSL'

    # Create a new context using system defaults, disable all but TLS1.2
    context = ssl.create_default_context()
    context.options &= ssl.OP_NO_TLSv1
    context.options &= ssl.OP_NO_TLSv1_1

    consumer = KafkaConsumer(environ.get('TOPIC'),
        bootstrap_servers = environ.get('KAFKA_BROKERS'),
        sasl_plain_username = environ.get('KAFKA_USERNAME'),  # tenancy/username/streampoolid
        sasl_plain_password = environ.get('KAFKA_PASSWORD'),  # auth token
        security_protocol = security_protocol,
        ssl_context = context,
        sasl_mechanism = sasl_mechanism,
        # api_version = (0,10),
        fetch_max_bytes = 1024 * 1024,  # 1MB
        auto_offset_reset='earliest',
        enable_auto_commit=True,
        group_id='my-group',
        value_deserializer=lambda x: x.decode('utf-8')
        )

    return consumer


if __name__ == '__main__':

    print("connecting...")
    consumer = get_consumer()
    print("ready to receive")

    for msg in consumer:
        print(msg)
