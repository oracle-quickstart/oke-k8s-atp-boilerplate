FROM python:3.9-slim

ENV PYTHONUNBUFFERED=1

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY src /src

CMD ["python", "/src/producer.py"]