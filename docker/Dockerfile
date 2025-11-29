# ---- BUILDER ----
FROM python:3.11-slim AS builder
WORKDIR /app

# copiar requirements
COPY requirements.txt .

# instalar librerías en /install
RUN pip install --prefix=/install --no-cache-dir -r requirements.txt


# ---- RUNTIME ----
FROM python:3.11-slim
RUN useradd --create-home --shell /bin/bash appuser
WORKDIR /app

# copiar librerías instaladas desde builder
COPY --from=builder /install /usr/local

# copiar código de la app
COPY app /app/app

# permisos para usuario no-root
RUN chown -R appuser:appuser /app
USER appuser

# exponer puerto
ENV PORT=8000
EXPOSE 8000

# comando de inicio
CMD ["python", "app/main.py"]
