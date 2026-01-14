# 🔄 Reconstruir Imágenes Docker con Código MCP

Tu cluster K3S está usando imágenes viejas que no incluyen el código del MongoDB MCP. Esta guía te ayudará a reconstruir y actualizar las imágenes.

## 🎯 Solución Rápida

### En tu Raspberry Pi 5

```bash
# 1. Navegar al proyecto
cd /ruta/a/langchain-local-llm

# 2. Ejecutar script automático de build y deploy
./k8s/build-and-deploy.sh
```

Esto hará:
1. ✅ Construir imagen con código MCP
2. ✅ Importar a K3S
3. ✅ Actualizar kustomization
4. ✅ Redesplegar pods
5. ✅ Verificar código MCP
6. ✅ Probar conexión MongoDB

## 📋 Paso a Paso Manual

Si prefieres hacerlo manualmente:

### Paso 1: Construir Imagen Docker (en RPI5)

```bash
# Navegar al proyecto
cd /ruta/a/langchain-local-llm

# Construir imagen para ARM64 (Raspberry Pi)
docker buildx build \
  --platform linux/arm64 \
  -t langchain-app:latest \
  -t langchain-app:$(date +v%Y%m%d-%H%M%S) \
  --load \
  .

# Verificar que el código MCP está en la imagen
docker run --rm langchain-app:latest ls /app/mcp_server/
```

Deberías ver:
```
__init__.py
config.py
example_usage.py
llm_integration_example.py
mongodb_mcp.py
query_examples.py
tools.py
README.md
```

### Paso 2: Importar a K3S

```bash
# Importar imagen al containerd de K3S
docker save langchain-app:latest | sudo k3s ctr images import -

# Verificar que está importada
sudo k3s ctr images ls | grep langchain-app
```

### Paso 3: Actualizar Deployment

```bash
# Aplicar cambios
kubectl apply -k k8s/base/

# Reiniciar deployment para forzar uso de nueva imagen
kubectl rollout restart deployment/langchain-api -n llm-services

# Esperar a que esté listo
kubectl rollout status deployment/langchain-api -n llm-services
```

### Paso 4: Verificar

```bash
# Verificar que el código MCP existe en el pod
kubectl exec -n llm-services deployment/langchain-api -- \
  ls -la /app/mcp_server/

# Probar MongoDB MCP
kubectl exec -n llm-services deployment/langchain-api -- \
  python /app/mcp_server/mongodb_mcp.py

# Ver logs
kubectl logs -n llm-services -l app=langchain-api --tail=50
```

## 🛠️ Opciones del Script

El script `build-and-deploy.sh` tiene varias opciones:

```bash
# Build completo y deploy
./k8s/build-and-deploy.sh

# Solo construir (sin desplegar)
./k8s/build-and-deploy.sh --build-only

# Solo desplegar (sin construir)
./k8s/build-and-deploy.sh --deploy-only

# Especificar versión
VERSION_TAG=v1.0.0 ./k8s/build-and-deploy.sh

# Usar registry remoto
REGISTRY=docker.io/tu-usuario ./k8s/build-and-deploy.sh

# Ver ayuda
./k8s/build-and-deploy.sh --help
```

## 🔍 Troubleshooting

### Error: "docker: command not found"

```bash
# Instalar Docker en Raspberry Pi
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

### Error: "k3s: command not found"

Si estás ejecutando el script desde tu máquina local (no en el RPI5):

```bash
# Usar opción --no-import para no importar localmente
./k8s/build-and-deploy.sh --no-import

# O construir y pushear a un registry
REGISTRY=docker.io/tu-usuario ./k8s/build-and-deploy.sh
```

### La imagen no se actualiza en K3S

```bash
# Borrar pods manualmente para forzar recreación
kubectl delete pod -n llm-services -l app=langchain-api

# Verificar imagePullPolicy en el deployment
kubectl get deployment langchain-api -n llm-services -o yaml | grep imagePullPolicy
# Debería ser: imagePullPolicy: IfNotPresent o Always
```

### El código MCP no aparece en el pod

```bash
# Verificar que está en la imagen Docker
docker run --rm langchain-app:latest ls /app/mcp_server/

# Si no está, verificar el Dockerfile
# Asegúrate de que el COPY incluye todo:
# COPY ./app /app
# WORKDIR /app
```

## 📦 Registry Remoto (Opcional)

Si tu cluster K3S está en múltiples nodos o quieres usar un registry:

### Docker Hub

```bash
# Login
docker login

# Build y push
docker buildx build \
  --platform linux/arm64 \
  -t tu-usuario/langchain-app:latest \
  --push \
  .

# Actualizar kustomization.yaml
vim k8s/base/kustomization.yaml
# Cambiar:
# images:
#   - name: langchain-app
#     newName: tu-usuario/langchain-app
#     newTag: latest

# Aplicar
kubectl apply -k k8s/base/
```

### Registry Privado

```bash
# Ejemplo con registry privado
export REGISTRY=registry.ejemplo.com

docker buildx build \
  --platform linux/arm64 \
  -t $REGISTRY/langchain-app:latest \
  --push \
  .

# Crear secret para pull
kubectl create secret docker-registry regcred \
  --docker-server=$REGISTRY \
  --docker-username=usuario \
  --docker-password=password \
  --docker-email=email@ejemplo.com \
  -n llm-services

# Actualizar deployment para usar el secret
kubectl patch serviceaccount default -n llm-services \
  -p '{"imagePullSecrets": [{"name": "regcred"}]}'
```

## 🚀 Workflow Completo

Para desarrollar y desplegar cambios:

```bash
# 1. Hacer cambios en el código
vim app/mcp_server/mongodb_mcp.py

# 2. Reconstruir y desplegar
./k8s/build-and-deploy.sh

# 3. Ver logs en tiempo real
kubectl logs -n llm-services -l app=langchain-api -f

# 4. Probar cambios
kubectl exec -n llm-services -it deployment/langchain-api -- \
  python /app/mcp_server/query_examples.py
```

## ✅ Checklist

- [ ] Código MCP presente en `/home/user/langchain-local-llm/app/mcp_server/`
- [ ] Dockerfile copia correctamente el código: `COPY ./app /app`
- [ ] Imagen construida: `docker images | grep langchain-app`
- [ ] Imagen importada a K3S: `sudo k3s ctr images ls | grep langchain-app`
- [ ] Deployment reiniciado: `kubectl rollout restart deployment/langchain-api`
- [ ] Pods corriendo: `kubectl get pods -n llm-services`
- [ ] Código MCP en pod: `kubectl exec ... ls /app/mcp_server/`
- [ ] Test exitoso: `kubectl exec ... python /app/mcp_server/mongodb_mcp.py`

## 🎯 Resultado Esperado

Después de seguir estos pasos, deberías poder ejecutar:

```bash
kubectl exec -n llm-services -it deployment/langchain-api -- \
  python /app/mcp_server/query_examples.py
```

Y ver la salida:

```
============================================================
MongoDB MCP Server - Ejemplos de Consulta
============================================================

Conectando a MongoDB...

========================================
🔍 EXPLORACIÓN DE LA BASE DE DATOS
========================================

📚 Colecciones disponibles:
--------------------------------------------------------------------
Base de datos: tu_base_de_datos
Total de colecciones: X

  1. coleccion1
     └─ Documentos: 1,234
     └─ Campos: campo1, campo2, campo3, ...
...
```

## 📚 Documentación Relacionada

- **Script de build**: `k8s/build-and-deploy.sh --help`
- **Guía de despliegue**: `k8s/K8S_MONGODB_DEPLOYMENT.md`
- **Documentación MCP**: `app/mcp_server/README.md`
- **Quick start K8S**: `k8s/README.md`

---

**¿Listo?** Ejecuta:

```bash
cd /ruta/a/langchain-local-llm
./k8s/build-and-deploy.sh
```
