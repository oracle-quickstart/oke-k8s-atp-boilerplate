FROM python:3.9-slim

ENV PYTHONUNBUFFERED=1

# Install Instant Client libraries required for cx_Oracle to connect to DB
RUN apt-get update \
    && apt-get install -y --no-install-recommends wget unzip libaio1 nano \
    && wget -qO instantclient.zip https://download.oracle.com/otn_software/linux/instantclient/211000/instantclient-basiclite-linux.x64-21.1.0.0.0.zip  \
    && unzip instantclient.zip -d / \
    && rm -f instantclient.zip \
    && apt-get remove -y wget unzip

ENV LD_LIBRARY_PATH=/instantclient_21_1
# The TNS_ADMIN path must be LD_LIBRARY_PATH/network/admin in the current state of cx_Oracle
ENV TNS_ADMIN=/instantclient_21_1/network/admin

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt
COPY src /src

CMD ["python", "/src/db_config.py"]