# LangChain + Ollama en Docker

Entorno completo para desarrollar con LangChain usando LLMs locales sin costes.

## 🚀 Plataformas Soportadas

- **Windows** (Docker Desktop con WSL2)
- **Linux** (x86_64 y ARM64)
- **macOS** (Intel y Apple Silicon)
- **🥧 Raspberry Pi 5** (8GB RAM) - [Ver guía específica](RASPBERRY_PI_SETUP.md)

## Requisitos Previos

### Windows / macOS / Linux (x86_64)
- **Docker Desktop** o Docker Engine
- **16 GB RAM** recomendado (8 GB mínimo)
- **10 GB espacio en disco** para modelos

### Raspberry Pi 5
- **8GB RAM** (recomendado)
- **Docker** instalado
- **32GB+ microSD** o SSD USB
- Ver [RASPBERRY_PI_SETUP.md](RASPBERRY_PI_SETUP.md) para guía completa

## Inicio Rápido

### 🥧 Para Raspberry Pi 5

**Usa la configuración optimizada para ARM64:**

```bash
# Instalación automática (recomendado)
chmod +x scripts/setup_rpi.sh
./scripts/setup_rpi.sh

# O manualmente:
docker compose -f docker-compose.rpi.yml up -d
docker exec ollama-server ollama pull gemma2:2b
```

📖 **Guía completa:** [RASPBERRY_PI_SETUP.md](RASPBERRY_PI_SETUP.md)

---

### 💻 Para Windows / macOS / Linux

### 1. Iniciar Ollama

```bash
# Iniciar solo Ollama primero
docker compose up -d ollama

# Verificar que esta corriendo
docker logs ollama-server
```

### 2. Descargar Modelos

```bash
# Modelo principal (4.7 GB)
docker exec ollama-server ollama pull llama3.2

# Modelo de embeddings para RAG (274 MB)
docker exec ollama-server ollama pull nomic-embed-text

# Verificar modelos instalados
docker exec ollama-server ollama list
```

### 3. Iniciar Aplicación

```bash
# Iniciar todo
docker compose up -d

# Ver logs
docker compose logs -f langchain-app
```

### 4. Ejecutar Ejemplos

```bash
# Ejemplos básicos
docker exec -it langchain-app python main.py

# Ejemplo RAG
docker exec -it langchain-app python rag_example.py

# Iniciar API REST
docker exec -it langchain-app python api_server.py
```

## Endpoints de la API

Una vez iniciada la API en `http://localhost:8000`:

| Endpoint | Metodo | Descripcion |
|----------|--------|-------------|
| `/` | GET | Health check |
| `/models` | GET | Listar modelos disponibles |
| `/chat` | POST | Chat simple |
| `/chat/stream` | POST | Chat con streaming |
| `/analyze` | POST | Analisis de texto |

### Ejemplo de uso con curl:

```bash
# Chat simple
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hola, quien eres?"}'

# Analisis de sentimiento
curl -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "Me encanta este producto!", "task": "sentiment"}'
```

## Modelos Disponibles

### Para PC / Laptop (16GB+ RAM)

| Modelo | Tamaño | RAM Necesaria | Uso Recomendado |
|--------|--------|---------------|-----------------|
| `llama3.2` | 4.7 GB | 16 GB | Uso general |
| `mistral` | 4.1 GB | 16 GB | Buen balance |
| `llama3.1:70b` | 40 GB | 64 GB | Alta calidad |

### Para Raspberry Pi / 8GB RAM

| Modelo | Tamaño | RAM Necesaria | Uso Recomendado |
|--------|--------|---------------|-----------------|
| `gemma2:2b` | 2.7 GB | 6 GB | ✅ Recomendado para RPI |
| `phi3:mini` | 2.3 GB | 6 GB | Código y razonamiento |
| `llama3.2:3b` | 2.0 GB | 5 GB | Tareas simples |
| `tinyllama` | 600 MB | 3 GB | Ultra ligero |

Para cambiar de modelo:

```bash
# Descargar nuevo modelo
docker exec ollama-server ollama pull mistral

# Configurar en .env
# MODEL_NAME=mistral
```

## Estructura del Proyecto

```
langchain-local-llm/
├── docker-compose.yml        # Configuración para PC/Laptop
├── docker-compose.rpi.yml    # 🥧 Configuración para Raspberry Pi
├── Dockerfile                # Imagen multi-arquitectura
├── requirements.txt          # Dependencias Python
├── .env.example             # Variables de entorno (PC)
├── .env.rpi                 # 🥧 Variables de entorno (RPI)
├── RASPBERRY_PI_SETUP.md    # 🥧 Guía completa para RPI
├── app/
│   ├── main.py              # Ejemplos básicos
│   ├── rag_example.py       # Ejemplo RAG completo
│   ├── agent_example.py     # Agentes con herramientas
│   └── api_server.py        # API REST con FastAPI
└── scripts/
    ├── setup.ps1            # Script Windows
    └── setup_rpi.sh         # 🥧 Script para Raspberry Pi
```

## Uso con GPU (NVIDIA)

Si tienes GPU NVIDIA, descomenta las lineas en `docker-compose.yml`:

```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: all
          capabilities: [gpu]
```

Requiere:
- NVIDIA drivers actualizados
- NVIDIA Container Toolkit instalado

## Troubleshooting

### Ollama no responde

```powershell
# Reiniciar contenedor
docker-compose restart ollama

# Ver logs
docker logs ollama-server
```

### Error de memoria

Reduce el modelo o aumenta la memoria de Docker Desktop:
Settings > Resources > Memory

### Modelo no encontrado

```powershell
# Listar modelos disponibles
docker exec ollama-server ollama list

# Descargar modelo faltante
docker exec ollama-server ollama pull <nombre-modelo>
```

## Desarrollo Local (sin Docker)

Si prefieres ejecutar sin Docker:

1. Instalar Ollama nativo: https://ollama.ai
2. Crear entorno virtual:
   ```powershell
   python -m venv venv
   .\venv\Scripts\Activate
   pip install -r requirements.txt
   ```
3. Ejecutar:
   ```powershell
   cd app
   python main.py
   ```
