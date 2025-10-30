FROM python:3.9-alpine

COPY requirements.txt ./requirements.txt
RUN pip3 install -r requirements.txt

COPY . .
CMD ["python3", "init_database.py", "latest.csv"]