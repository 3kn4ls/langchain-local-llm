# 🚀 Despliegue de MongoDB MCP en K3S

Guía completa para desplegar el servidor MCP de MongoDB en un cluster K3S (Kubernetes).

## 📋 Requisitos Previos

- Cluster K3S funcionando en tu Raspberry Pi 5
- `kubectl` configurado para acceder al cluster
- Acceso a una base de datos MongoDB (local, remota, o MongoDB Atlas)
- Imágenes Docker construidas con el código del MCP

## 🏗️ Arquitectura en K8S

```
┌─────────────────────────────────────────────────────────────┐
│                    Namespace: llm-services                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐      ┌──────────────┐                   │
│  │   ConfigMap  │      │    Secret    │                    │
│  │ langchain-   │      │  mongodb-    │                    │
│  │   config     │      │   secret     │                    │
│  │              │      │              │                    │
│  │ • Timeout    │      │ • URI        │                    │
│  │ • Pool Size  │      │ • Database   │                    │
│  └──────┬───────┘      └──────┬───────┘                    │
│         │                     │                            │
│         └──────────┬──────────┘                            │
│                    │                                       │
│         ┌──────────▼──────────┐                            │
│         │  Deployment:        │                            │
│         │  langchain-api      │                            │
│         │                     │                            │
│         │  • MongoDB MCP      │                            │
│         │  • FastAPI Server   │                            │
│         │  • RAG Service      │                            │
│         └──────────┬──────────┘                            │
│                    │                                       │
│         ┌──────────▼──────────┐                            │
│         │    Service          │                            │
│         │  langchain-api-svc  │                            │
│         └─────────────────────┘                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                       │
                       │ Externa
                       ▼
              ┌─────────────────┐
              │   MongoDB       │
              │   (Externo)     │
              │                 │
              │ • Local         │
              │ • Atlas         │
              │ • Self-hosted   │
              └─────────────────┘
```

## 📦 Recursos Creados

### 1. `mongodb-secret.yaml`
Secret que contiene las credenciales de MongoDB:
- `MONGODB_URI`: URI completa de conexión
- `MONGODB_DATABASE`: Nombre de la base de datos

### 2. `configmap.yaml` (actualizado)
ConfigMap con configuración no sensible:
- `MONGODB_TIMEOUT`: Timeout de conexión (5000ms)
- `MONGODB_MAX_POOL_SIZE`: Tamaño del pool de conexiones (10)

### 3. `langchain-api-deployment.yaml` (actualizado)
Deployment con variables de entorno de MongoDB inyectadas desde Secret y ConfigMap.

## 🔧 Configuración Paso a Paso

### 1. Configurar Credenciales de MongoDB

Edita `k8s/base/mongodb-secret.yaml` con tus credenciales reales:

```yaml
stringData:
  # Para MongoDB local en el host de la RPI5
  MONGODB_URI: "mongodb://192.168.1.100:27017"

  # Para MongoDB Atlas
  # MONGODB_URI: "mongodb+srv://usuario:password@cluster.mongodb.net"

  # Para MongoDB con autenticación
  # MONGODB_URI: "mongodb://usuario:password@host:27017/database?authSource=admin"

  # Para MongoDB dentro del mismo cluster K3S
  # MONGODB_URI: "mongodb://mongodb-service.llm-services.svc.cluster.local:27017"

  MONGODB_DATABASE: "tu_base_de_datos"
```

**Opciones de URI según tu setup:**

#### Opción A: MongoDB en el host de la Raspberry Pi 5
```yaml
MONGODB_URI: "mongodb://192.168.1.100:27017"
```
(Reemplaza `192.168.1.100` con la IP real de tu RPI5)

#### Opción B: MongoDB Atlas (Cloud)
```yaml
MONGODB_URI: "mongodb+srv://usuario:password@cluster.mongodb.net"
```

#### Opción C: MongoDB en otro servidor de tu red
```yaml
MONGODB_URI: "mongodb://192.168.1.50:27017"
```

#### Opción D: MongoDB corriendo en el mismo cluster K3S
Si desplegaras MongoDB dentro del cluster, usarías:
```yaml
MONGODB_URI: "mongodb://mongodb-service.llm-services.svc.cluster.local:27017"
```

### 2. Construir y Pushear la Imagen Docker (si no lo has hecho)

```bash
# Construir imagen con el código del MCP
cd /home/user/langchain-local-llm

# Para arquitectura ARM64 (RPI5)
docker buildx build --platform linux/arm64 -t langchain-app:latest --load .

# O si tienes un registry privado
docker buildx build --platform linux/arm64 -t tu-registry/langchain-app:latest --push .

# Actualizar tag en k8s/base/kustomization.yaml
```

### 3. Aplicar los Manifiestos

#### Opción A: Aplicar todo con Kustomize (Recomendado)

```bash
# Desde la raíz del proyecto
kubectl apply -k k8s/base/

# Verificar que se crearon los recursos
kubectl get all -n llm-services
kubectl get configmap,secret -n llm-services
```

#### Opción B: Aplicar recursos individualmente

```bash
# Aplicar en orden
kubectl apply -f k8s/base/namespace.yaml
kubectl apply -f k8s/base/configmap.yaml
kubectl apply -f k8s/base/mongodb-secret.yaml
kubectl apply -f k8s/base/langchain-api-deployment.yaml
# ... resto de recursos
```

### 4. Verificar el Despliegue

```bash
# Ver pods
kubectl get pods -n llm-services

# Ver logs del pod langchain-api
kubectl logs -n llm-services -l app=langchain-api --tail=100 -f

# Ver variables de entorno (verificar que MongoDB está configurado)
kubectl exec -n llm-services -it deployment/langchain-api -- env | grep MONGODB
```

Deberías ver:
```
MONGODB_URI=mongodb://...
MONGODB_DATABASE=tu_base_de_datos
MONGODB_TIMEOUT=5000
MONGODB_MAX_POOL_SIZE=10
```

### 5. Probar la Conexión a MongoDB

```bash
# Ejecutar script de prueba dentro del pod
kubectl exec -n llm-services -it deployment/langchain-api -- \
  python /app/mcp_server/mongodb_mcp.py

# Explorar la base de datos
kubectl exec -n llm-services -it deployment/langchain-api -- \
  python /app/mcp_server/query_examples.py
```

## 🔍 Verificación y Debugging

### Ver Logs en Tiempo Real

```bash
# Logs de langchain-api
kubectl logs -n llm-services -l app=langchain-api -f

# Logs de todos los pods
kubectl logs -n llm-services --all-containers=true -f
```

### Verificar Configuración

```bash
# Ver el Secret (ofuscado)
kubectl get secret mongodb-secret -n llm-services -o yaml

# Ver el ConfigMap
kubectl get configmap langchain-config -n llm-services -o yaml

# Describir el deployment
kubectl describe deployment langchain-api -n llm-services
```

### Probar Conexión Manualmente

```bash
# Entrar al pod
kubectl exec -n llm-services -it deployment/langchain-api -- /bin/bash

# Dentro del pod, probar conexión
python3 << 'EOF'
from pymongo import MongoClient
import os

uri = os.getenv("MONGODB_URI")
db_name = os.getenv("MONGODB_DATABASE")

print(f"URI: {uri}")
print(f"Database: {db_name}")

client = MongoClient(uri)
print("✅ Conexión exitosa!")
print(f"Bases de datos: {client.list_database_names()}")

db = client[db_name]
print(f"Colecciones en '{db_name}': {db.list_collection_names()}")
client.close()
EOF
```

## 🔄 Actualizar Configuración

### Actualizar Credenciales de MongoDB

```bash
# Editar el secret
kubectl edit secret mongodb-secret -n llm-services

# O volver a aplicar el archivo
kubectl apply -f k8s/base/mongodb-secret.yaml

# Reiniciar los pods para que tomen la nueva configuración
kubectl rollout restart deployment/langchain-api -n llm-services

# Ver el progreso
kubectl rollout status deployment/langchain-api -n llm-services
```

### Actualizar ConfigMap

```bash
# Editar el configmap
kubectl edit configmap langchain-config -n llm-services

# O volver a aplicar
kubectl apply -f k8s/base/configmap.yaml

# Reiniciar deployment
kubectl rollout restart deployment/langchain-api -n llm-services
```

## 📊 Monitoreo

### Ver Estado de los Pods

```bash
# Estado general
kubectl get pods -n llm-services -w

# Eventos del namespace
kubectl get events -n llm-services --sort-by='.lastTimestamp'

# Recursos utilizados
kubectl top pods -n llm-services
```

### Health Checks

Los pods tienen health checks configurados:
- **Liveness**: Verifica que la aplicación sigue respondiendo
- **Readiness**: Verifica que está lista para recibir tráfico
- **Startup**: Da tiempo de arranque inicial

```bash
# Ver el estado de los health checks
kubectl describe pod -n llm-services -l app=langchain-api | grep -A 10 "Liveness\|Readiness"
```

## 🚨 Troubleshooting

### Pod no inicia (CrashLoopBackOff)

```bash
# Ver logs del pod fallido
kubectl logs -n llm-services -l app=langchain-api --previous

# Ver eventos
kubectl describe pod -n llm-services -l app=langchain-api

# Causas comunes:
# 1. URI de MongoDB incorrecta
# 2. MongoDB no accesible desde el cluster
# 3. Credenciales inválidas
# 4. Base de datos no existe
```

### Error de conexión a MongoDB

**Síntoma**: Logs muestran "Connection refused" o "Connection timeout"

**Solución**:

1. **Verificar que MongoDB es accesible desde el cluster**:
   ```bash
   # Desde un pod del cluster
   kubectl run -n llm-services test-pod --image=busybox --rm -it --restart=Never -- \
     wget -O- http://192.168.1.100:27017

   # O probar con netcat
   kubectl run -n llm-services test-pod --image=busybox --rm -it --restart=Never -- \
     nc -zv 192.168.1.100 27017
   ```

2. **Si MongoDB está en el host de K3S**:
   - K3S por defecto usa `containerd` que no tiene `host.docker.internal`
   - Usa la IP real del host: `192.168.1.X`
   - O configura un Service de tipo ExternalName

3. **Firewall**: Verificar que el puerto de MongoDB (27017) está abierto

### Secret no se aplica

```bash
# Eliminar y recrear el secret
kubectl delete secret mongodb-secret -n llm-services
kubectl apply -f k8s/base/mongodb-secret.yaml

# Verificar que existe
kubectl get secret mongodb-secret -n llm-services

# Ver contenido (base64 encoded)
kubectl get secret mongodb-secret -n llm-services -o jsonpath='{.data.MONGODB_URI}' | base64 -d
```

## 🔐 Seguridad

### Mejores Prácticas

1. **No commitear el Secret con credenciales reales**:
   ```bash
   # Agregar a .gitignore
   echo "k8s/base/mongodb-secret.yaml" >> .gitignore

   # O mantener una plantilla
   cp k8s/base/mongodb-secret.yaml k8s/base/mongodb-secret.example.yaml
   ```

2. **Usar Sealed Secrets** (recomendado para producción):
   ```bash
   # Instalar Sealed Secrets controller
   kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

   # Crear sealed secret
   kubeseal -f k8s/base/mongodb-secret.yaml -w k8s/base/mongodb-sealed-secret.yaml
   ```

3. **Limitar permisos de red con NetworkPolicy** (ya incluido en el proyecto)

## 📈 Escalado

### Escalar Réplicas

```bash
# Aumentar réplicas para mayor disponibilidad
kubectl scale deployment langchain-api -n llm-services --replicas=2

# O editar el deployment
kubectl edit deployment langchain-api -n llm-services

# Ver el HPA (Horizontal Pod Autoscaler)
kubectl get hpa -n llm-services
```

**Nota**: El pool de conexiones de MongoDB se comparte entre réplicas. Ajusta `MONGODB_MAX_POOL_SIZE` según el número de réplicas.

## 🧪 Testing

### Test Básico

```bash
# Ejecutar tests del MCP
kubectl exec -n llm-services -it deployment/langchain-api -- \
  python -m pytest /app/mcp_server/

# Probar herramientas MCP
kubectl exec -n llm-services -it deployment/langchain-api -- \
  python /app/mcp_server/mongodb_mcp.py
```

### Test de Integración

```bash
# Probar endpoint de la API
kubectl port-forward -n llm-services svc/langchain-api 8000:8000

# En otra terminal
curl http://localhost:8000/
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "¿Qué colecciones hay en MongoDB?"}]}'
```

## 📚 Recursos Adicionales

- **Documentación completa**: `/app/mcp_server/README.md`
- **Ejemplos de uso**: `/app/mcp_server/query_examples.py`
- **Integración con LLM**: `/app/mcp_server/llm_integration_example.py`
- **Setup general**: `/MONGODB_SETUP.md`

## ✅ Checklist de Despliegue

- [ ] MongoDB accesible desde el cluster
- [ ] Secret `mongodb-secret.yaml` configurado con credenciales reales
- [ ] Imagen Docker construida con el código del MCP
- [ ] Manifiestos aplicados con `kubectl apply -k k8s/base/`
- [ ] Pods en estado `Running`
- [ ] Logs sin errores de conexión
- [ ] Test de conexión exitoso con `mongodb_mcp.py`
- [ ] API respondiendo correctamente

## 🆘 Ayuda

Si tienes problemas:

```bash
# Ver todos los recursos
kubectl get all,configmap,secret -n llm-services

# Ver logs completos
kubectl logs -n llm-services -l app=langchain-api --tail=500

# Describir el pod con problemas
kubectl describe pod -n llm-services <pod-name>

# Ver eventos del cluster
kubectl get events -n llm-services --sort-by='.lastTimestamp' | tail -20
```

---

**¿Listo?** Ejecuta:

```bash
# 1. Configurar credenciales
vim k8s/base/mongodb-secret.yaml

# 2. Aplicar
kubectl apply -k k8s/base/

# 3. Verificar
kubectl get pods -n llm-services -w

# 4. Probar
kubectl exec -n llm-services -it deployment/langchain-api -- \
  python /app/mcp_server/query_examples.py
```
