## Copyright (c) 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

FROM python:3.9-slim as builder

# Install Instant Client libraries required for cx_Oracle to connect to DB
RUN apt-get update \
    && apt-get install -y --no-install-recommends wget unzip libaio1 nano \
    && wget -qO instantclient.zip https://download.oracle.com/otn_software/linux/instantclient/211000/instantclient-basiclite-linux.x64-21.1.0.0.0.zip  \
    && unzip instantclient.zip -d / \
    && rm -f instantclient.zip \
    && apt-get remove -y wget unzip \
    && rm -rf /var/lib/apt/lists/*

# The TNS_ADMIN path must be LD_LIBRARY_PATH/network/admin in the current state of cx_Oracle
ENV LD_LIBRARY_PATH=/instantclient_21_1 \
    TNS_ADMIN=/instantclient_21_1/network/admin \
    PYTHONUNBUFFERED=1

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt
COPY src /src

# Image that allows auto-reload of code when files changes
# to be used with the sync functionality
FROM builder as autoreload
RUN apt-get update \
    && apt-get install -y --no-install-recommends entr procps \
    && rm -rf /var/lib/apt/lists/*

ENV ENTR_INOTIFY_WORKAROUND=1
# The Job won't quit in this mode.
CMD find /src | entr -r python /src/db_config.py

# Output image for debug: same image as builder but with straight Python command
FROM builder as debug
CMD ["python", "/src/db_config.py"]

# Output image for prod: same image as builder, no special wrapping here
FROM builder as prod
CMD ["python", "/src/db_config.py"]