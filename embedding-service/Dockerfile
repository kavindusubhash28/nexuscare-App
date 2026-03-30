FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV TMPDIR=/tmp

EXPOSE 8001

CMD ["gunicorn", "--bind", "0.0.0.0:8001", "--worker-tmp-dir", "/tmp", "--workers", "1", "--timeout", "120", "app:app"]