from python:slim

ENV PYTHONUNBUFFERED=1

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt
COPY consumer.py /consumer.py

CMD ["python", "consumer.py"]