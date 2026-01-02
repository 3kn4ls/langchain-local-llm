# Docker Compose - Explicación Detallada

Este documento explica cada parte del archivo `docker-compose.yml` para que cualquier persona, incluso sin conocimientos de IA, pueda entender qué hace cada componente.

---

## ¿Qué es Docker Compose?

**Docker Compose** es una herramienta que permite definir y ejecutar múltiples contenedores Docker al mismo tiempo. Piensa en ello como una "receta" que describe:
- Qué programas necesitas (imágenes)
- Cómo se comunican entre sí
- Qué recursos comparten

En lugar de ejecutar cada contenedor manualmente, Docker Compose te permite iniciar todo el sistema con un solo comando.

---

## Estructura General del Archivo

```yaml
version: '3.8'        # Versión de Docker Compose que usamos

services:             # Lista de "contenedores" o "servicios"
  ollama:            # Primer servicio (servidor de IA)
  langchain-app:     # Segundo servicio (aplicación)

volumes:              # Espacios de almacenamiento persistente
```

---

# Servicio 1: Ollama (Servidor de IA Local)

## ¿Qué es Ollama?

**Ollama** es como tener ChatGPT corriendo en tu propia computadora. Es un programa que ejecuta modelos de inteligencia artificial de forma local, sin necesidad de internet ni de pagar por APIs externas.

### Analogía Simple
Imagina que en lugar de llamar a un restaurante para pedir comida (usar ChatGPT en internet), tienes tu propia cocina profesional en casa (Ollama en tu PC). Puedes cocinar (generar texto con IA) cuando quieras, gratis y sin internet.

---

## Configuración del Servicio Ollama

```yaml
ollama:
  image: ollama/ollama:latest
```

### `image: ollama/ollama:latest`
- **¿Qué es?** La "imagen Docker" es como una plantilla o instalador preconfigurado
- **ollama/ollama** es el nombre de la imagen oficial de Ollama en Docker Hub
- **:latest** significa "dame la versión más reciente"
- **Docker Hub** es como una tienda de aplicaciones para contenedores

**Analogía:** Es como descargar la app de WhatsApp desde la Play Store - `ollama/ollama:latest` es el nombre y versión de la app.

---

```yaml
container_name: ollama-server
```

### `container_name: ollama-server`
- Le ponemos un nombre fácil de recordar al contenedor
- Sin esto, Docker le pondría un nombre aleatorio como "langchain_ollama_1"
- Útil para ejecutar comandos como: `docker logs ollama-server`

**Analogía:** Es como ponerle "Mi PC del trabajo" a tu computadora en lugar de dejarla como "DESKTOP-X7K2P9"

---

```yaml
ports:
  - "11434:11434"
```

### `ports: "11434:11434"`
- **Puerto:** Es como el número de apartamento en un edificio
- Los programas usan puertos para comunicarse
- **11434** es el puerto que usa Ollama por defecto
- **"11434:11434"** significa: "El puerto 11434 de tu Windows conecta con el puerto 11434 del contenedor"

**Analogía:** Es como redirigir el correo de tu apartamento 11434 (Windows) al apartamento 11434 del edificio (contenedor Docker).

---

```yaml
volumes:
  - ollama_data:/root/.ollama
```

### `volumes: ollama_data:/root/.ollama`
- **Volumen:** Espacio de almacenamiento persistente (no se borra al apagar el contenedor)
- **ollama_data** es el nombre del volumen (definido al final del archivo)
- **/root/.ollama** es la carpeta dentro del contenedor donde Ollama guarda los modelos de IA

**¿Por qué es importante?**
Los modelos de IA pesan varios GB (ej: Llama 3.2 pesa ~4.7 GB). Sin un volumen, cada vez que apagas el contenedor, tendrías que descargar los modelos de nuevo.

**Analogía:** Es como tener un disco duro externo para guardar tus archivos. Aunque apagues el ordenador (contenedor), los archivos (modelos de IA) se mantienen guardados.

---

```yaml
# Para GPU NVIDIA (opcional, descomentar si tienes GPU)
# deploy:
#   resources:
#     reservations:
#       devices:
#         - driver: nvidia
#           count: all
#           capabilities: [gpu]
```

### Configuración de GPU (Opcional)

- **GPU:** Procesador gráfico (como NVIDIA RTX, GTX)
- Las GPUs aceleran los cálculos de IA de forma dramática (10-50x más rápido)
- Esta sección está comentada (#) porque es opcional

**¿Cuándo activarla?**
- Si tienes una tarjeta gráfica NVIDIA (RTX 3060, 4070, etc.)
- Si has instalado NVIDIA Container Toolkit
- Si quieres respuestas mucho más rápidas del modelo de IA

**Analogía:** Es como usar una licuadora eléctrica (GPU) en lugar de batir a mano (CPU). El resultado es el mismo, pero la velocidad es muy diferente.

---

```yaml
restart: unless-stopped
```

### `restart: unless-stopped`
- **Reinicio automático:** Si el contenedor falla o se apaga, Docker lo reinicia solo
- **unless-stopped:** Solo se detiene si TÚ lo paras manualmente

**Analogía:** Es como configurar que tu PC se reinicie automáticamente si se cuelga, excepto si tú lo apagas a propósito.

---

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:11434/api/tags"]
  interval: 30s
  timeout: 10s
  retries: 3
```

### `healthcheck`
- **Chequeo de salud:** Docker verifica periódicamente que Ollama esté funcionando
- **test:** Comando para verificar (hace una petición HTTP a la API de Ollama)
- **interval: 30s** → Verifica cada 30 segundos
- **timeout: 10s** → Si no responde en 10 segundos, marca como "no saludable"
- **retries: 3** → Intenta 3 veces antes de marcar como "muerto"

**Analogía:** Es como un médico que te toma el pulso cada 30 segundos para asegurarse de que estás bien.

---

# Servicio 2: LangChain App (Aplicación de IA)

## ¿Qué es LangChain?

**LangChain** es un framework (conjunto de herramientas) para construir aplicaciones con modelos de lenguaje (IA). Facilita tareas como:
- Chatbots con memoria
- Análisis de documentos (RAG)
- Automatización de tareas
- Integración de múltiples modelos de IA

### Analogía Simple
Si Ollama es la "cocina" (el motor de IA), LangChain es el "libro de recetas" que te dice cómo combinar ingredientes para hacer platos específicos (aplicaciones útiles).

---

## Configuración del Servicio LangChain

```yaml
langchain-app:
  build:
    context: .
    dockerfile: Dockerfile
```

### `build`
- **Diferencia clave:** En lugar de descargar una imagen como con Ollama, aquí CONSTRUIMOS nuestra propia imagen
- **context: .** → Usa la carpeta actual (`.`) como base
- **dockerfile: Dockerfile** → Usa las instrucciones del archivo `Dockerfile` para construir la imagen

**¿Qué hay en el Dockerfile?**
1. Imagen base de Python 3.11
2. Instalación de dependencias (LangChain, FastAPI, etc.)
3. Copia del código de la aplicación

**Analogía:** Es como construir tu casa a medida (build) en lugar de comprar una prefabricada (image).

---

```yaml
container_name: langchain-app
```

### `container_name: langchain-app`
- Nombre amigable para el contenedor de la aplicación
- Facilita ejecutar comandos como: `docker exec -it langchain-app python main.py`

---

```yaml
ports:
  - "8000:8000"
```

### `ports: "8000:8000"`
- **Puerto 8000:** Puerto estándar para aplicaciones web en Python (FastAPI, Uvicorn)
- Si inicias la API REST, podrás acceder desde tu navegador en `http://localhost:8000`

**Analogía:** Es como el número de extensión telefónica de un departamento específico.

---

```yaml
environment:
  - OLLAMA_BASE_URL=http://ollama:11434
  - PYTHONUNBUFFERED=1
```

### `environment` - Variables de Entorno

**OLLAMA_BASE_URL=http://ollama:11434**
- Le dice a la app dónde encontrar el servidor de Ollama
- **ollama** es el nombre del servicio (Docker crea automáticamente una red interna)
- **11434** es el puerto de Ollama

**PYTHONUNBUFFERED=1**
- Configuración técnica de Python para que los logs se muestren en tiempo real
- Útil para debugging

**Analogía:** Es como darle a un empleado nuevo la dirección de la oficina del jefe (Ollama) para que pueda consultarle cosas.

---

```yaml
volumes:
  - ./app:/app
```

### `volumes: ./app:/app`
- **./app** → Carpeta `app/` en tu Windows
- **/app** → Carpeta `/app` dentro del contenedor
- **Conexión en vivo:** Los cambios que hagas en `app/main.py` se reflejan inmediatamente en el contenedor

**¿Por qué es útil?**
Puedes editar el código en Visual Studio Code en Windows, y no necesitas reconstruir el contenedor para ver los cambios.

**Analogía:** Es como tener un espejo mágico - lo que cambias en tu casa (Windows) se refleja automáticamente en el contenedor.

---

```yaml
depends_on:
  ollama:
    condition: service_healthy
```

### `depends_on`
- **Orden de inicio:** LangChain App solo se inicia DESPUÉS de que Ollama esté saludable
- **condition: service_healthy** → Espera a que el healthcheck de Ollama sea exitoso

**¿Por qué es necesario?**
Si LangChain App se inicia antes que Ollama, intentará conectarse y fallará porque Ollama aún no está listo.

**Analogía:** Es como esperar a que el café esté listo antes de servirlo. No sirves una taza vacía.

---

```yaml
restart: unless-stopped
```

### `restart: unless-stopped`
- Igual que en Ollama: reinicia automáticamente si falla

---

# Sección: Volumes

```yaml
volumes:
  ollama_data:
    driver: local
```

## `volumes: ollama_data`

- **Definición del volumen:** Aquí creamos el volumen `ollama_data` que usa Ollama
- **driver: local** → Almacenamiento en el disco duro local
- Docker gestiona automáticamente dónde se guarda físicamente (usualmente en `C:\ProgramData\docker\volumes\`)

**¿Cuánto espacio ocupa?**
- Llama 3.2: ~4.7 GB
- Nomic-embed-text: ~274 MB
- Total: ~5-8 GB dependiendo de cuántos modelos descargues

**Analogía:** Es como alquilar un trastero para guardar cosas que no quieres perder.

---

# Diagrama de Flujo del Sistema

```
┌─────────────────────────────────────────────────────────┐
│                      TU WINDOWS                          │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │         Docker Desktop                         │    │
│  │                                                │    │
│  │  ┌──────────────┐        ┌─────────────────┐  │    │
│  │  │   Ollama     │        │  LangChain App  │  │    │
│  │  │  (Servidor)  │◄───────┤  (Aplicación)   │  │    │
│  │  │              │        │                 │  │    │
│  │  │ Puerto 11434 │        │   Puerto 8000   │  │    │
│  │  └──────┬───────┘        └────────┬────────┘  │    │
│  │         │                         │           │    │
│  │         ▼                         ▼           │    │
│  │  ┌──────────────┐        ┌─────────────────┐  │    │
│  │  │ollama_data   │        │   ./app (sync)  │  │    │
│  │  │(Modelos IA)  │        │   (Tu código)   │  │    │
│  │  └──────────────┘        └─────────────────┘  │    │
│  │                                                │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
│  Acceso desde navegador:                                │
│  http://localhost:8000  (API de LangChain)              │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

# Flujo de Trabajo: ¿Cómo Funciona Todo Junto?

## 1. **Inicio del Sistema**

```powershell
docker-compose up -d
```

1. Docker lee `docker-compose.yml`
2. Descarga la imagen `ollama/ollama:latest` (si no la tiene)
3. Crea el volumen `ollama_data`
4. Inicia el contenedor `ollama-server`
5. Espera a que Ollama esté saludable (healthcheck)
6. Construye la imagen de `langchain-app` usando el Dockerfile
7. Inicia el contenedor `langchain-app`

---

## 2. **Descarga de Modelos**

```powershell
docker exec ollama-server ollama pull llama3.2
```

1. Te conectas al contenedor `ollama-server`
2. Ejecutas el comando `ollama pull llama3.2`
3. Ollama descarga el modelo desde internet (~4.7 GB)
4. Lo guarda en `/root/.ollama` dentro del contenedor
5. Gracias al volumen `ollama_data`, el modelo se persiste en tu disco duro

**Primera vez:** Tarda 10-15 minutos (dependiendo de tu internet)
**Después:** El modelo ya está descargado, no necesitas repetir este paso

---

## 3. **Ejecución de Ejemplos**

```powershell
docker exec -it langchain-app python main.py
```

1. Te conectas al contenedor `langchain-app`
2. Ejecutas el script `main.py`
3. El script se conecta a `http://ollama:11434` (Ollama)
4. Envía prompts al modelo de IA
5. Ollama procesa la solicitud usando Llama 3.2
6. Devuelve la respuesta a LangChain
7. LangChain muestra el resultado en tu terminal

---

## 4. **Desarrollo y Modificación de Código**

1. Editas `app/main.py` en Visual Studio Code (Windows)
2. Los cambios se sincronizan automáticamente con el contenedor (gracias al volumen `./app:/app`)
3. Ejecutas de nuevo: `docker exec -it langchain-app python main.py`
4. Ves los cambios inmediatamente, sin reconstruir el contenedor

---

# Imágenes Docker Utilizadas

## 1. ollama/ollama:latest

**Desarrollador:** Ollama Team
**Tamaño:** ~1.5 GB (imagen base)
**Licencia:** MIT (Open Source)
**Repositorio oficial:** https://hub.docker.com/r/ollama/ollama

**¿Qué incluye?**
- Servidor HTTP para servir modelos de IA
- Runtime para ejecutar LLMs (Large Language Models)
- Gestión de modelos (descargar, listar, eliminar)
- Soporte para múltiples arquitecturas (CPU, NVIDIA GPU, AMD GPU)

**Modelos compatibles:**
- Llama 3.2, Llama 3.1, Llama 2
- Mistral, Mixtral
- Phi-3 (Microsoft)
- Gemma (Google)
- Codestral (para código)
- Y muchos más...

**Tecnología interna:**
- Escrito en Go
- Usa llama.cpp para inferencia optimizada
- API REST compatible con OpenAI

---

## 2. python:3.11-slim

**Desarrollador:** Python Software Foundation (imagen oficial)
**Tamaño:** ~120 MB (imagen base)
**Licencia:** PSF License (Python Software Foundation)
**Repositorio oficial:** https://hub.docker.com/_/python

**¿Qué incluye?**
- Python 3.11 (versión estable y moderna)
- pip (gestor de paquetes de Python)
- Herramientas básicas de Linux (Debian slim)

**¿Por qué "slim"?**
- Versión minimalista sin herramientas innecesarias
- Reduce el tamaño de la imagen final
- Más rápida de descargar y construir

**Usado para:**
- Construir la imagen `langchain-app`
- Ejecutar scripts de Python con LangChain

---

# Recursos del Sistema

## Uso de RAM

| Componente | RAM Mínima | RAM Recomendada |
|------------|------------|------------------|
| Docker Desktop | 2 GB | 4 GB |
| Ollama (servidor) | 2 GB | 4 GB |
| Llama 3.2 (modelo) | 8 GB | 16 GB |
| LangChain App | 512 MB | 1 GB |
| **TOTAL** | **12 GB** | **25 GB** |

**Configuración en Docker Desktop:**
Settings > Resources > Memory

---

## Uso de Disco

| Componente | Espacio |
|------------|---------|
| Imagen ollama/ollama | ~1.5 GB |
| Imagen python:3.11-slim | ~120 MB |
| Modelo Llama 3.2 | ~4.7 GB |
| Modelo nomic-embed-text | ~274 MB |
| Dependencias Python | ~500 MB |
| **TOTAL** | **~7-8 GB** |

---

## Uso de CPU/GPU

**Con CPU (sin GPU):**
- Respuestas: 1-5 segundos por consulta simple
- Ideal para desarrollo y pruebas
- Funciona en cualquier PC moderna

**Con GPU NVIDIA:**
- Respuestas: 0.2-1 segundo
- Recomendado para producción
- Requiere RTX/GTX con 8+ GB VRAM

---

# Comandos Útiles

## Ver logs en tiempo real

```powershell
# Logs de todos los servicios
docker-compose logs -f

# Solo logs de Ollama
docker logs -f ollama-server

# Solo logs de LangChain App
docker logs -f langchain-app
```

---

## Gestión de contenedores

```powershell
# Ver estado de los contenedores
docker-compose ps

# Reiniciar servicios
docker-compose restart

# Detener todo
docker-compose down

# Detener y eliminar volúmenes (borra modelos)
docker-compose down -v
```

---

## Gestión de modelos en Ollama

```powershell
# Listar modelos instalados
docker exec ollama-server ollama list

# Descargar modelo
docker exec ollama-server ollama pull mistral

# Eliminar modelo
docker exec ollama-server ollama rm llama3.2

# Probar un modelo
docker exec ollama-server ollama run llama3.2 "Hola, ¿cómo estás?"
```

---

## Información del sistema

```powershell
# Ver uso de espacio de volúmenes
docker volume ls
docker volume inspect langchain-local-llm_ollama_data

# Ver uso de recursos
docker stats

# Ver imágenes descargadas
docker images
```

---

# Preguntas Frecuentes

## ¿Necesito internet para usar esto?

**Descarga inicial:** Sí, necesitas internet para:
- Descargar las imágenes Docker (~1.6 GB)
- Descargar los modelos de IA (~5 GB)

**Uso posterior:** No, una vez descargado todo, funciona 100% offline.

---

## ¿Cuánto cuesta usar esto?

**Coste: $0.00**

- Ollama es gratis y open source
- Los modelos son gratuitos
- No hay límites de uso
- No necesitas API keys

---

## ¿Qué pasa si reinicio mi PC?

Los contenedores se detendrán, pero:
- Los modelos descargados se mantienen (gracias al volumen)
- Para reiniciar: `docker-compose up -d`

---

## ¿Puedo usar otros modelos?

Sí, Ollama soporta decenas de modelos:

```powershell
# Ver todos los modelos disponibles en ollama.com/library
docker exec ollama-server ollama pull mistral
docker exec ollama-server ollama pull phi3:mini
docker exec ollama-server ollama pull codellama
```

Para cambiar el modelo por defecto, edita la variable `MODEL_NAME` en `docker-compose.yml` o `.env`.

---

## ¿Es seguro?

**Sí, muy seguro:**
- Todo corre localmente en tu PC
- Tus datos NO se envían a internet
- No hay telemetría ni tracking
- Open source (puedes revisar el código)

---

## ¿Funciona en Mac o Linux?

Sí, este proyecto es compatible con:
- Windows 10/11 con Docker Desktop
- macOS con Docker Desktop
- Linux con Docker Engine

Solo cambian algunos comandos de PowerShell por comandos de terminal Unix.

---

# Conclusión

Este archivo `docker-compose.yml` orquesta dos servicios principales:

1. **Ollama:** El "motor" de IA que ejecuta modelos de lenguaje localmente
2. **LangChain App:** La "aplicación" que usa Ollama para construir funcionalidades útiles

Juntos forman un sistema completo para desarrollar aplicaciones de IA sin costes, sin internet (después de la descarga inicial), y con total privacidad.

**Próximos pasos:**
1. Ejecuta `docker-compose up -d`
2. Descarga un modelo: `docker exec ollama-server ollama pull llama3.2`
3. Ejecuta los ejemplos: `docker exec -it langchain-app python main.py`
4. Empieza a construir tus propias aplicaciones de IA

---

**¿Dudas?** Revisa los logs con `docker-compose logs -f` o consulta la documentación oficial:
- Ollama: https://ollama.ai/
- LangChain: https://python.langchain.com/
- Docker Compose: https://docs.docker.com/compose/
