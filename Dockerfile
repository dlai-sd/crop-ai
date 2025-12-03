FROM python:3.10-slim

WORKDIR /app

# system deps for common python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -U pip && pip install --no-cache-dir -r requirements.txt

# copy package and app files
COPY src/ src/

ENV PYTHONPATH=/app/src

EXPOSE 8000

CMD ["uvicorn", "crop_ai.api:app", "--host", "0.0.0.0", "--port", "8000"]
