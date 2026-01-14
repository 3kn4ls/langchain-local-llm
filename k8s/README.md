# 🚀 Kubernetes Deployment - MongoDB MCP

Manifiestos de Kubernetes para desplegar LangChain + Ollama + MongoDB MCP en K3S.

## 🎯 Quick Start

```bash
# 1. Configurar credenciales de MongoDB
vim k8s/base/mongodb-secret.yaml

# 2. Desplegar (automático)
./k8s/deploy-mongodb-mcp.sh

# 3. Ver logs
kubectl logs -n llm-services -l app=langchain-api -f
```

## 📁 Estructura

```
k8s/
├── base/
│   ├── namespace.yaml                  # Namespace: llm-services
│   ├── configmap.yaml                  # Configuración general + MongoDB
│   ├── mongodb-secret.yaml             # 🔐 Credenciales de MongoDB (EDITAR)
│   ├── langchain-api-deployment.yaml   # Deployment con MongoDB MCP
│   ├── ollama-statefulset.yaml         # Ollama LLM
│   ├── services.yaml                   # Services
│   ├── frontend-deployment.yaml        # Frontend React
│   ├── pvc.yaml                        # PersistentVolumeClaims
│   ├── ingress.yaml                    # Ingress (opcional)
│   ├── hpa.yaml                        # HorizontalPodAutoscaler
│   └── kustomization.yaml              # Kustomize config
│
├── deploy-mongodb-mcp.sh               # 🚀 Script de despliegue
├── K8S_MONGODB_DEPLOYMENT.md           # 📖 Documentación completa
└── README.md                           # Este archivo
```

## ⚙️ Configuración Requerida

### 1. MongoDB Secret

**IMPORTANTE**: Debes editar `base/mongodb-secret.yaml` antes de desplegar:

```yaml
stringData:
  # Opción A: MongoDB en tu RPI5 (reemplaza con IP real)
  MONGODB_URI: "mongodb://192.168.1.100:27017"

  # Opción B: MongoDB Atlas
  # MONGODB_URI: "mongodb+srv://usuario:password@cluster.mongodb.net"

  # Opción C: MongoDB en otro servidor
  # MONGODB_URI: "mongodb://192.168.1.50:27017"

  MONGODB_DATABASE: "tu_base_de_datos"
```

### 2. Imágenes Docker

Actualiza los tags de las imágenes en `base/kustomization.yaml`:

```yaml
images:
  - name: langchain-app
    newTag: latest  # o tu tag específico
  - name: langchain-frontend
    newTag: latest
```

## 🚀 Despliegue

### Opción 1: Script Automático (Recomendado)

```bash
# Despliegue completo con verificaciones
./k8s/deploy-mongodb-mcp.sh

# Solo verificar configuración
./k8s/deploy-mongodb-mcp.sh --check

# Ver logs en tiempo real
./k8s/deploy-mongodb-mcp.sh --logs

# Eliminar recursos
./k8s/deploy-mongodb-mcp.sh --delete
```

### Opción 2: Manual con Kustomize

```bash
# Aplicar todos los manifiestos
kubectl apply -k k8s/base/

# Verificar
kubectl get all -n llm-services

# Ver logs
kubectl logs -n llm-services -l app=langchain-api -f
```

### Opción 3: Manual Individual

```bash
# Aplicar en orden
kubectl apply -f k8s/base/namespace.yaml
kubectl apply -f k8s/base/configmap.yaml
kubectl apply -f k8s/base/mongodb-secret.yaml
kubectl apply -f k8s/base/pvc.yaml
kubectl apply -f k8s/base/ollama-statefulset.yaml
kubectl apply -f k8s/base/services.yaml
kubectl apply -f k8s/base/langchain-api-deployment.yaml
kubectl apply -f k8s/base/frontend-deployment.yaml
kubectl apply -f k8s/base/frontend-service.yaml
```

## 🔍 Verificación

### Ver Estado

```bash
# Todos los recursos
kubectl get all -n llm-services

# Solo pods
kubectl get pods -n llm-services -w

# Secrets y ConfigMaps
kubectl get configmap,secret -n llm-services
```

### Ver Logs

```bash
# Logs de langchain-api
kubectl logs -n llm-services -l app=langchain-api -f

# Logs de Ollama
kubectl logs -n llm-services -l app=ollama -f

# Eventos del namespace
kubectl get events -n llm-services --sort-by='.lastTimestamp'
```

### Probar MongoDB MCP

```bash
# Test básico de conexión
kubectl exec -n llm-services -it deployment/langchain-api -- \
  python /app/mcp_server/mongodb_mcp.py

# Explorar base de datos
kubectl exec -n llm-services -it deployment/langchain-api -- \
  python /app/mcp_server/query_examples.py

# Verificar variables de entorno
kubectl exec -n llm-services deployment/langchain-api -- env | grep MONGODB
```

## 🔧 Configuración Avanzada

### Actualizar Secret

```bash
# Método 1: Editar directamente
kubectl edit secret mongodb-secret -n llm-services

# Método 2: Aplicar archivo actualizado
kubectl apply -f k8s/base/mongodb-secret.yaml

# Reiniciar pods para aplicar cambios
kubectl rollout restart deployment/langchain-api -n llm-services
```

### Escalar Réplicas

```bash
# Aumentar réplicas
kubectl scale deployment langchain-api -n llm-services --replicas=2

# Ver estado del escalado
kubectl get hpa -n llm-services
```

### Acceder a la API

```bash
# Port forward para acceso local
kubectl port-forward -n llm-services svc/langchain-api 8000:8000

# Luego abre en tu navegador: http://localhost:8000
```

### Acceder al Frontend

```bash
# Port forward para el frontend
kubectl port-forward -n llm-services svc/frontend 3000:80

# Abre en tu navegador: http://localhost:3000
```

## 🐛 Troubleshooting

### Pod no inicia

```bash
# Ver logs del pod fallido
kubectl logs -n llm-services -l app=langchain-api --previous

# Describir el pod
kubectl describe pod -n llm-services -l app=langchain-api

# Ver eventos
kubectl get events -n llm-services --sort-by='.lastTimestamp' | tail -20
```

### Problemas de conexión a MongoDB

```bash
# Probar conectividad desde el cluster
kubectl run test-mongo -n llm-services --image=busybox --rm -it --restart=Never -- \
  nc -zv 192.168.1.100 27017

# Verificar URI en el Secret
kubectl get secret mongodb-secret -n llm-services -o jsonpath='{.data.MONGODB_URI}' | base64 -d

# Ver logs con errores de MongoDB
kubectl logs -n llm-services -l app=langchain-api --tail=100 | grep -i mongo
```

### Reiniciar Servicios

```bash
# Reiniciar langchain-api
kubectl rollout restart deployment/langchain-api -n llm-services

# Reiniciar Ollama
kubectl rollout restart statefulset/ollama -n llm-services

# Ver progreso del restart
kubectl rollout status deployment/langchain-api -n llm-services
```

## 📊 Monitoreo

### Recursos del Sistema

```bash
# CPU y Memoria de los pods
kubectl top pods -n llm-services

# Recursos del nodo
kubectl top nodes

# Describe el HPA
kubectl describe hpa -n llm-services
```

### Health Checks

```bash
# Ver el estado de los health checks
kubectl get pods -n llm-services -o wide

# Describir deployment para ver probes
kubectl describe deployment langchain-api -n llm-services | grep -A 5 "Liveness\|Readiness"
```

## 🧹 Limpieza

### Eliminar Todo

```bash
# Con script
./k8s/deploy-mongodb-mcp.sh --delete

# O con kustomize
kubectl delete -k k8s/base/

# O eliminar namespace completo (¡cuidado!)
kubectl delete namespace llm-services
```

### Eliminar Solo MongoDB MCP

```bash
# Eliminar secret y actualizar deployment
kubectl delete secret mongodb-secret -n llm-services

# Remover variables de entorno del deployment
kubectl edit deployment langchain-api -n llm-services
# (Eliminar sección de MongoDB)
```

## 📚 Documentación Adicional

- **Guía completa de K8S**: `K8S_MONGODB_DEPLOYMENT.md`
- **Documentación del MCP**: `../app/mcp_server/README.md`
- **Setup general**: `../MONGODB_SETUP.md`
- **Ejemplos de uso**: `../app/mcp_server/query_examples.py`

## 🔐 Seguridad

### Mejores Prácticas

1. **No commitear secrets reales**:
   ```bash
   # Agregar a .gitignore
   echo "k8s/base/mongodb-secret.yaml" >> .gitignore
   ```

2. **Usar Sealed Secrets** (producción):
   ```bash
   # Instalar controller
   kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

   # Sellar secret
   kubeseal -f k8s/base/mongodb-secret.yaml -w k8s/base/mongodb-sealed-secret.yaml
   ```

3. **RBAC**: El namespace usa NetworkPolicies para restringir tráfico

## 🎯 Checklist de Despliegue

- [ ] MongoDB accesible desde el cluster
- [ ] `mongodb-secret.yaml` configurado con credenciales reales
- [ ] Imágenes Docker construidas y disponibles
- [ ] Tags de imágenes actualizados en `kustomization.yaml`
- [ ] Manifiestos aplicados: `kubectl apply -k k8s/base/`
- [ ] Pods en estado `Running`: `kubectl get pods -n llm-services`
- [ ] Logs sin errores: `kubectl logs -n llm-services -l app=langchain-api`
- [ ] Test de MongoDB exitoso: `python /app/mcp_server/mongodb_mcp.py`
- [ ] API responde: `curl http://localhost:8000/` (con port-forward)

## 🆘 Ayuda Rápida

```bash
# Ver todo el namespace
kubectl get all,cm,secret,pvc -n llm-services

# Entrar a un pod para debugging
kubectl exec -n llm-services -it deployment/langchain-api -- /bin/bash

# Ver configuración completa
kubectl describe deployment langchain-api -n llm-services

# Obtener ayuda del script
./k8s/deploy-mongodb-mcp.sh --help
```

## 📞 Soporte

Si tienes problemas:
1. Revisa `K8S_MONGODB_DEPLOYMENT.md` para troubleshooting detallado
2. Verifica logs: `kubectl logs -n llm-services -l app=langchain-api`
3. Revisa eventos: `kubectl get events -n llm-services`
4. Prueba conexión: `kubectl exec ... python /app/mcp_server/mongodb_mcp.py`

---

**¿Listo para empezar?**

```bash
./k8s/deploy-mongodb-mcp.sh
```
