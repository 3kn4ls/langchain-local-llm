# Guía de Instalación para Raspberry Pi 5

Esta guía te ayudará a ejecutar LangChain + Ollama en tu Raspberry Pi 5 con 8GB de RAM.

---

## Índice

1. [Requisitos](#requisitos)
2. [Instalación Rápida](#instalación-rápida)
3. [Instalación Manual](#instalación-manual)
4. [Modelos Recomendados](#modelos-recomendados)
5. [Uso Básico](#uso-básico)
6. [Optimización de Rendimiento](#optimización-de-rendimiento)
7. [Solución de Problemas](#solución-de-problemas)
8. [Monitoreo de Recursos](#monitoreo-de-recursos)

---

## Requisitos

### Hardware
- **Raspberry Pi 5** con 8GB de RAM (recomendado)
- Tarjeta microSD de al menos 32GB (se recomiendan 64GB o SSD)
- Fuente de alimentación oficial de Raspberry Pi 5 (5V/5A USB-C)
- Sistema de refrigeración (disipador o ventilador activo recomendado)

### Software
- **Raspberry Pi OS** (64-bit) - Bookworm o posterior
- **Docker** y **Docker Compose** instalados
- Al menos **10GB de espacio libre** en disco

---

## Instalación Rápida

### 1. Instalar Docker (si no está instalado)

```bash
# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Agregar tu usuario al grupo docker (evita usar sudo)
sudo usermod -aG docker $USER

# Reiniciar sesión para aplicar cambios
newgrp docker

# Verificar instalación
docker --version
docker compose version
```

### 2. Clonar o descargar este repositorio

```bash
cd ~
git clone <URL_DEL_REPOSITORIO>
cd langchain-local-llm
```

### 3. Ejecutar script de configuración automática

```bash
# Dar permisos de ejecución
chmod +x scripts/setup_rpi.sh

# Ejecutar script
./scripts/setup_rpi.sh
```

El script hará lo siguiente:
- ✅ Verificar requisitos del sistema
- ✅ Configurar variables de entorno
- ✅ Iniciar servicios Docker
- ✅ Descargar modelos LLM (te preguntará cuál quieres)
- ✅ Verificar que todo funciona

---

## Instalación Manual

Si prefieres hacerlo paso a paso:

### 1. Configurar variables de entorno

```bash
# Copiar archivo de configuración para RPI
cp .env.rpi .env

# (Opcional) Editar configuración
nano .env
```

### 2. Iniciar servicios Docker

```bash
# Iniciar servicios con docker-compose específico para RPI
docker compose -f docker-compose.rpi.yml up -d

# Ver logs
docker compose -f docker-compose.rpi.yml logs -f
```

### 3. Esperar a que Ollama esté listo

```bash
# Verificar que Ollama responde
docker exec ollama-server curl http://localhost:11434/api/tags
```

### 4. Descargar modelos

```bash
# Opción 1: Gemma 2B (RECOMENDADO para RPI)
docker exec ollama-server ollama pull gemma2:2b

# Opción 2: Phi-3 Mini
docker exec ollama-server ollama pull phi3:mini

# Opción 3: Llama 3.2 3B
docker exec ollama-server ollama pull llama3.2:3b

# Modelo de embeddings (para RAG)
docker exec ollama-server ollama pull nomic-embed-text
```

### 5. Verificar instalación

```bash
# Listar modelos instalados
docker exec ollama-server ollama list

# Probar el modelo
docker exec ollama-server ollama run gemma2:2b "Hola, ¿cómo estás?"
```

---

## Modelos Recomendados

Para **Raspberry Pi 5 con 8GB de RAM**, estos son los modelos más adecuados:

### 🏆 Gemma 2B (Recomendado)

```bash
docker exec ollama-server ollama pull gemma2:2b
```

**Características:**
- **Tamaño:** ~2.7GB en RAM
- **Calidad:** Excelente para su tamaño
- **Velocidad:** ~10-15 tokens/segundo en RPI 5
- **Fabricante:** Google
- **Ideal para:** Uso general, chatbots, asistentes

### 🥈 Phi-3 Mini

```bash
docker exec ollama-server ollama pull phi3:mini
```

**Características:**
- **Tamaño:** ~2.3GB en RAM
- **Calidad:** Muy bueno en razonamiento
- **Velocidad:** ~12-18 tokens/segundo en RPI 5
- **Fabricante:** Microsoft
- **Ideal para:** Código, razonamiento lógico

### 🥉 Llama 3.2 3B

```bash
docker exec ollama-server ollama pull llama3.2:3b
```

**Características:**
- **Tamaño:** ~2GB en RAM
- **Calidad:** Buena para tareas simples
- **Velocidad:** ~15-20 tokens/segundo en RPI 5
- **Fabricante:** Meta
- **Ideal para:** Respuestas rápidas, tareas simples

### ⚡ TinyLlama (Ultra ligero)

```bash
docker exec ollama-server ollama pull tinyllama
```

**Características:**
- **Tamaño:** ~600MB en RAM
- **Calidad:** Básica, pero funcional
- **Velocidad:** ~25-30 tokens/segundo en RPI 5
- **Ideal para:** Pruebas, desarrollo, recursos muy limitados

### 📊 Nomic Embed Text (Embeddings para RAG)

```bash
docker exec ollama-server ollama pull nomic-embed-text
```

**Características:**
- **Tamaño:** ~274MB
- **Uso:** Generación de embeddings para búsqueda semántica
- **Necesario para:** Sistemas RAG (búsqueda en documentos)

---

## Uso Básico

### Ejecutar ejemplos interactivos

```bash
# Ejemplos básicos de LangChain
docker exec -it langchain-app python main.py

# Ejemplos de RAG (búsqueda en documentos)
docker exec -it langchain-app python rag_example.py

# Ejemplos de agentes con herramientas
docker exec -it langchain-app python agent_example.py
```

### Iniciar API web

```bash
# Reiniciar el contenedor con el servidor API
docker compose -f docker-compose.rpi.yml restart langchain-app
docker compose -f docker-compose.rpi.yml exec -d langchain-app python api_server.py

# La API estará disponible en:
# http://<IP_DE_TU_RPI>:8000
```

### Probar la API con curl

```bash
# Health check
curl http://localhost:8000/

# Chat simple
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Explica qué es Python en 2 oraciones"}'

# Listar modelos disponibles
curl http://localhost:8000/models
```

### Acceder a shell interactivo de Python

```bash
# Abrir Python dentro del contenedor
docker exec -it langchain-app python

# Luego puedes ejecutar código Python:
# >>> from langchain_ollama import ChatOllama
# >>> llm = ChatOllama(model="gemma2:2b")
# >>> response = llm.invoke("Hola")
# >>> print(response.content)
```

---

## Optimización de Rendimiento

### 1. Refrigeración

La Raspberry Pi 5 puede calentarse bajo carga intensiva:

```bash
# Ver temperatura actual
vcgencmd measure_temp

# Monitorear temperatura en tiempo real
watch -n 1 vcgencmd measure_temp
```

**Recomendaciones:**
- Temperatura ideal: < 60°C
- Con carga: 60-75°C es normal
- Si supera 80°C: Considera agregar refrigeración activa
- Thermal throttling comienza a ~85°C

### 2. Usar SSD en lugar de microSD

Para mejor rendimiento:

```bash
# Los modelos se almacenan en /var/lib/docker/volumes
# Mover Docker a SSD USB mejora significativamente el rendimiento
```

### 3. Limitar uso de RAM

El `docker-compose.rpi.yml` ya incluye límites de memoria:

```yaml
deploy:
  resources:
    limits:
      memory: 6G  # Ollama: máximo 6GB
```

### 4. Overclock (Avanzado)

**⚠️ ADVERTENCIA:** Overclock puede causar inestabilidad. Solo para usuarios avanzados.

```bash
# Editar /boot/firmware/config.txt
sudo nano /boot/firmware/config.txt

# Agregar:
# arm_freq=2800  # Frecuencia de CPU (2.4GHz por defecto, hasta 3GHz)
# gpu_freq=900   # Frecuencia de GPU
# over_voltage=6 # Voltaje (necesario para overclock)

# Reiniciar
sudo reboot
```

### 5. Desactivar servicios innecesarios

```bash
# Ver servicios activos
systemctl list-units --type=service --state=running

# Desactivar servicios que no necesites
# Ejemplo: Bluetooth si no lo usas
sudo systemctl disable bluetooth
```

---

## Solución de Problemas

### Problema 1: "Cannot connect to Docker daemon"

**Error:**
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**Solución:**
```bash
# Verificar que Docker está corriendo
sudo systemctl status docker

# Iniciar Docker si está detenido
sudo systemctl start docker

# Verificar que tu usuario está en el grupo docker
groups $USER

# Si no está, agregarlo:
sudo usermod -aG docker $USER
newgrp docker
```

---

### Problema 2: Contenedor Ollama no inicia

**Ver logs:**
```bash
docker compose -f docker-compose.rpi.yml logs ollama
```

**Posibles soluciones:**
```bash
# Limpiar y reiniciar
docker compose -f docker-compose.rpi.yml down
docker system prune -f
docker compose -f docker-compose.rpi.yml up -d
```

---

### Problema 3: Respuestas muy lentas

**Síntomas:** El modelo tarda mucho en responder

**Soluciones:**

1. **Usar un modelo más ligero:**
```bash
# Cambiar de gemma2:2b a tinyllama
docker exec ollama-server ollama pull tinyllama
# Editar .env y cambiar MODEL_NAME=tinyllama
```

2. **Verificar temperatura:**
```bash
vcgencmd measure_temp
# Si está en thermal throttling (>85°C), mejora la refrigeración
```

3. **Verificar uso de RAM:**
```bash
free -h
# Si la RAM está llena, cierra aplicaciones o usa un modelo más pequeño
```

---

### Problema 4: Error "Out of Memory"

**Síntomas:** El contenedor se cierra solo o responde con errores

**Soluciones:**

1. **Usar un modelo más pequeño:**
```bash
# tinyllama usa solo 600MB
docker exec ollama-server ollama pull tinyllama
```

2. **Aumentar swap (memoria virtual):**
```bash
# Ver swap actual
free -h

# Aumentar swap a 4GB
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
# Cambiar CONF_SWAPSIZE=4096
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

3. **Reducir límites de memoria en docker-compose:**
```yaml
# En docker-compose.rpi.yml
deploy:
  resources:
    limits:
      memory: 4G  # Reducir de 6G a 4G
```

---

### Problema 5: Modelo no encontrado

**Error:**
```
Error: model 'gemma2:2b' not found
```

**Solución:**
```bash
# Verificar modelos instalados
docker exec ollama-server ollama list

# Descargar el modelo
docker exec ollama-server ollama pull gemma2:2b

# Verificar nuevamente
docker exec ollama-server ollama list
```

---

### Problema 6: Puerto 8000 ya en uso

**Error:**
```
Bind for 0.0.0.0:8000 failed: port is already allocated
```

**Solución:**
```bash
# Ver qué proceso usa el puerto 8000
sudo lsof -i :8000

# Opción 1: Detener el proceso
sudo kill <PID>

# Opción 2: Cambiar el puerto en docker-compose.rpi.yml
# Editar:
# ports:
#   - "8080:8000"  # Cambiar de 8000 a 8080
```

---

## Monitoreo de Recursos

### Ver uso en tiempo real

```bash
# Uso de CPU, RAM y Red de los contenedores
docker stats

# Información del sistema
htop  # o top si htop no está instalado

# Temperatura de la CPU
watch -n 1 vcgencmd measure_temp

# Espacio en disco
df -h
```

### Logs de contenedores

```bash
# Ver logs de todos los servicios
docker compose -f docker-compose.rpi.yml logs -f

# Ver logs solo de Ollama
docker compose -f docker-compose.rpi.yml logs -f ollama

# Ver logs solo de LangChain
docker compose -f docker-compose.rpi.yml logs -f langchain-app

# Ver últimas 50 líneas
docker compose -f docker-compose.rpi.yml logs --tail=50
```

### Limpieza de espacio

```bash
# Ver espacio usado por Docker
docker system df

# Limpiar imágenes, contenedores y volúmenes no usados
docker system prune -a

# ⚠️ CUIDADO: Esto borra los modelos descargados
docker volume prune

# Listar volúmenes
docker volume ls

# Borrar un volumen específico
docker volume rm <VOLUME_NAME>
```

---

## Comandos Útiles

### Gestión de servicios

```bash
# Iniciar servicios
docker compose -f docker-compose.rpi.yml up -d

# Detener servicios
docker compose -f docker-compose.rpi.yml down

# Reiniciar servicios
docker compose -f docker-compose.rpi.yml restart

# Ver estado de los servicios
docker compose -f docker-compose.rpi.yml ps

# Reconstruir imágenes (después de cambios)
docker compose -f docker-compose.rpi.yml build --no-cache
docker compose -f docker-compose.rpi.yml up -d
```

### Gestión de modelos

```bash
# Listar modelos instalados
docker exec ollama-server ollama list

# Descargar un modelo
docker exec ollama-server ollama pull <modelo>

# Borrar un modelo
docker exec ollama-server ollama rm <modelo>

# Probar un modelo directamente
docker exec -it ollama-server ollama run gemma2:2b "Hola"

# Ver información de un modelo
docker exec ollama-server ollama show gemma2:2b
```

---

## Comparativa de Rendimiento

Velocidades aproximadas en **Raspberry Pi 5 (8GB)** con refrigeración activa:

| Modelo | RAM Usada | Tokens/seg | Tiempo de respuesta (50 tokens) |
|--------|-----------|------------|--------------------------------|
| TinyLlama | 600MB | 25-30 | ~2 segundos |
| Llama 3.2 3B | 2GB | 15-20 | ~3-4 segundos |
| Phi-3 Mini | 2.3GB | 12-18 | ~3-5 segundos |
| Gemma 2B | 2.7GB | 10-15 | ~4-6 segundos |

**Notas:**
- Velocidades varían según la complejidad del prompt
- Primera ejecución es más lenta (carga del modelo)
- Con thermal throttling (>85°C), la velocidad puede reducirse a la mitad

---

## Mejores Prácticas

1. **Usa refrigeración activa** - Mantiene rendimiento constante
2. **SSD sobre microSD** - Mejora significativamente la velocidad
3. **Cierra aplicaciones innecesarias** - Libera RAM para el LLM
4. **Usa modelos pequeños** - Gemma 2B o Phi-3 Mini son ideales
5. **Monitorea recursos** - Usa `docker stats` y `vcgencmd measure_temp`
6. **Habilita swap** - Ayuda cuando la RAM es insuficiente
7. **Actualiza Raspberry Pi OS** - Mejoras de rendimiento constantes

---

## Próximos Pasos

Una vez que todo funcione:

1. **Personaliza prompts** - Experimenta con diferentes instrucciones
2. **Crea tu RAG** - Indexa tus propios documentos
3. **Desarrolla una API** - Integra con tus aplicaciones
4. **Automatiza tareas** - Scripts para análisis de textos, etc.

---

## Recursos Adicionales

- **Documentación de Ollama:** https://ollama.ai/
- **Documentación de LangChain:** https://python.langchain.com/
- **Foro de Raspberry Pi:** https://forums.raspberrypi.com/
- **Comunidad Ollama Discord:** https://discord.gg/ollama

---

## Soporte

Si encuentras problemas:

1. Revisa los logs: `docker compose -f docker-compose.rpi.yml logs`
2. Verifica recursos: `docker stats` y `free -h`
3. Consulta esta documentación
4. Abre un issue en el repositorio del proyecto

---

**¡Disfruta de tu LLM local en Raspberry Pi! 🎉🥧**

*Última actualización: 2026-01-06*
