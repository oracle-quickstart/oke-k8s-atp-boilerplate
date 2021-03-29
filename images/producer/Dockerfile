## Copyright (c) 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

FROM python:3.9-slim as builder

ENV PYTHONUNBUFFERED=1

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

CMD find /src | entr -r python /src/producer.py


# Output image for prod: same image as builder but with straight Python command
FROM builder as debug
CMD ["python", "/src/producer.py"]

# Output image for prod: same image as builder but with straight Python command
FROM builder as prod
CMD ["python", "/src/producer.py"]