#!/bin/bash
# Script para construir imagenes VERSIONADAS y actualizar Kustomization

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
echo "   Build & Push VERSIONADO (k3s ARM64)"
echo "======================================================"
echo ""

# Verificar Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker no encontrado"
    exit 1
fi

# Directorio raíz del proyecto
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

# Generar versión basada en fecha
VERSION="v$(date +%Y%m%d-%H%M%S)"
print_info "Versión generada: $VERSION"

BACKEND_IMAGE="langchain-app"
FRONTEND_IMAGE="langchain-frontend"

# Construir Backend
print_info "1/5 Construyendo Backend ($VERSION)..."
docker build \
  --platform linux/arm64 \
  -t "$BACKEND_IMAGE:$VERSION" \
  -t "$BACKEND_IMAGE:latest" \
  -f Dockerfile \
  . || { print_error "Fallo build backend"; exit 1; }
print_success "Backend construido"

# Construir Frontend
print_info "2/5 Construyendo Frontend ($VERSION)..."
docker build \
  --platform linux/arm64 \
  -t "$FRONTEND_IMAGE:$VERSION" \
  -t "$FRONTEND_IMAGE:latest" \
  -f frontend/Dockerfile \
  frontend/ || { print_error "Fallo build frontend"; exit 1; }
print_success "Frontend construido"

# Importar a k3s
print_info "3/5 Importando imagenes a k3s..."
import_image() {
  local img=$1
  if command -v k3s &> /dev/null; then
    docker save "$img" | sudo k3s ctr images import -
  else
    # Fallback si no hay pipe directo (raro) o sudo requiere pass
    TMP_TAR="/tmp/img_$(date +%s)_$RANDOM.tar"
    docker save "$img" -o "$TMP_TAR"
    sudo ctr -n k8s.io images import "$TMP_TAR"
    rm "$TMP_TAR"
  fi
}

print_info "Importando $BACKEND_IMAGE:$VERSION..."
import_image "$BACKEND_IMAGE:$VERSION"

print_info "Importando $FRONTEND_IMAGE:$VERSION..."
import_image "$FRONTEND_IMAGE:$VERSION"

print_success "Imagenes importadas a k3s"

# Actualizar Kustomization
print_info "4/5 Actualizando k8s/base/kustomization.yaml..."
KUSTOMIZATION_FILE="k8s/base/kustomization.yaml"

# Usamos sed para actualizar el YAML
# Buscamos 'name: langchain-app' y en la siguiente linea reemplazamos 'newTag: ...'
sed -i "/name: langchain-app/{n;s/newTag: .*/newTag: $VERSION/}" "$KUSTOMIZATION_FILE"
sed -i "/name: langchain-frontend/{n;s/newTag: .*/newTag: $VERSION/}" "$KUSTOMIZATION_FILE"

# Verificar si cambió (opcional, grep)
if grep -q "$VERSION" "$KUSTOMIZATION_FILE"; then
    print_success "kustomization.yaml actualizado con $VERSION"
else
    print_error "No se pudo actualizar kustomization.yaml (verifica el formato del archivo)"
    exit 1
fi

echo ""
echo "======================================================"
print_success "¡Build completo: $VERSION!"
echo "======================================================"
echo ""
print_info "Siguientes pasos:"
echo "  1. (Opcional) git commit -am 'Bump version to $VERSION'"
echo "  2. cd k8s/scripts && ./deploy.sh"
echo ""
