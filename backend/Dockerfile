FROM python:3.11-slim

WORKDIR /app

# تثبيت الاعتماديات الأساسية لتجميع حزم بايثون و postgresql
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# تشغيل السيرفر على المنفذ الممرر من Railway تلقائياً
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
