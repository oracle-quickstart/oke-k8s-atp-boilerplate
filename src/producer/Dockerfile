from python:slim

ENV PYTHONUNBUFFERED=1

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY producer.py /producer.py

CMD ["python", "producer.py"]