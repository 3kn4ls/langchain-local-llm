#!/bin/bash
# Script de despliegue para k3s usando Kustomize
# Despliega LangChain + Ollama en Kubernetes

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${NC}ℹ $1${NC}"; }

echo "======================================================"
echo "   Despliegue de LangChain + Ollama (Kustomize)"
echo "======================================================"
echo ""

# Verificar kubectl
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl no encontrado. Instálalo primero."
    exit 1
fi

# Directorio base
K8S_BASE="$(cd "$(dirname "$0")/.." && pwd)/base"
cd "$K8S_BASE"

# Verificar kustomization.yaml
if [ ! -f "kustomization.yaml" ]; then
    print_error "No se encontró kustomization.yaml en $K8S_BASE"
    exit 1
fi

print_info "Aplicando configuración desde: $K8S_BASE"

# Aplicar todo con Kustomize
print_info "1/4 Aplicando manifiestos (kubectl apply -k)...";
kubectl apply -k . || { print_error "Fallo al aplicar kustomize"; exit 1; }
print_success "Manifiestos aplicados"

# Esperar a recursos clave
print_info "2/4 Esperando a que el PVC esté bound...";
# Esperamos un poco para que el PVC se cree si es nuevo
sleep 2
kubectl wait --for=jsonpath='{.status.phase}'=Bound \
  -n llm-services pvc/ollama-models-pvc --timeout=60s || {
  print_warning "PVC no está bound aún, continuando..."
}

print_info "3/4 Esperando a que los servicios estén listos...";

# Esperar a Ollama
print_info "  - Verificando Ollama...";
kubectl wait --for=condition=ready pod -l app=ollama \
  -n llm-services --timeout=300s || {
  print_warning "Ollama tarda en iniciar (descargando modelos?). Verifica logs."
}

# Esperar a Backend
print_info "  - Verificando Backend API...";
kubectl wait --for=condition=ready pod -l app=langchain-api \
  -n llm-services --timeout=120s || {
  print_warning "API Backend no está ready."
}

# Esperar a Frontend
print_info "  - Verificando Frontend...";
kubectl wait --for=condition=ready pod -l app=langchain-frontend \
  -n llm-services --timeout=60s

# Reiniciar deployments para asegurar que tomen la ultima imagen si no cambió el tag (aunque usamos versioning ahora)
# Esto es redundante si el tag cambió, pero seguro si reutilizamos tags.
# print_info "Forzando rollout restart (por seguridad)..."
# kubectl rollout restart deployment/langchain-api -n llm-services
# kubectl rollout restart deployment/langchain-frontend -n llm-services

echo ""
echo "======================================================"
print_success "Despliegue completado!"
echo "======================================================"
echo ""

# Mostrar estado
print_info "Estado de los pods:"
kubectl get pods -n llm-services

echo ""
print_info "Ingress:"
kubectl get ingress -n llm-services

echo ""
print_success "¡Todo listo! 🚀"