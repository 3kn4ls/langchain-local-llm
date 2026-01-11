# Dockerfile para LangChain App
# Compatible con x86_64 y ARM64 (Raspberry Pi)
FROM python:3.11-slim

WORKDIR /app

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements primero (cache de Docker)
COPY requirements.txt .

# Instalar dependencias Python
# --no-cache-dir reduce tamaño de imagen
# --timeout aumenta tiempo de espera (útil en RPI con conexión lenta)
RUN pip install --no-cache-dir --timeout=300 -r requirements.txt && \
    python -m nltk.downloader punkt punkt_tab averaged_perceptron_tagger

# Copiar codigo de la aplicacion
COPY app/ .

# Puerto para la API (si usas FastAPI)
EXPOSE 8000

# Comando por defecto
CMD ["python", "main.py"]
