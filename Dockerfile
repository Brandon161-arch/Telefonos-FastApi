# ============ Etapa 1: Backend FastAPI ============
FROM python:3.13-slim AS backend

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Instalar dependencias (usa cache por capas)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código de la app
COPY app ./app
COPY run.py .

# Exponer puerto de la API
EXPOSE 8000

# Health check para orquestadores (Coolify)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=3)" || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
