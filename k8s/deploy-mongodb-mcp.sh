#!/bin/bash

###############################################################################
# Deploy MongoDB MCP to K3S
#
# Script para desplegar el servidor MCP de MongoDB en K3S
###############################################################################

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
NAMESPACE="llm-services"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="${SCRIPT_DIR}/base"

###############################################################################
# Funciones de utilidad
###############################################################################

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_prerequisites() {
    print_header "Verificando Requisitos"

    # Verificar kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl no está instalado"
        exit 1
    fi
    print_success "kubectl encontrado: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"

    # Verificar acceso al cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "No se puede conectar al cluster de Kubernetes"
        exit 1
    fi
    print_success "Cluster accesible: $(kubectl config current-context)"

    # Verificar que existe el directorio base
    if [ ! -d "$BASE_DIR" ]; then
        print_error "Directorio $BASE_DIR no encontrado"
        exit 1
    fi
    print_success "Directorio de manifiestos encontrado"
}

check_mongodb_secret() {
    print_header "Verificando Configuración de MongoDB"

    SECRET_FILE="${BASE_DIR}/mongodb-secret.yaml"

    if [ ! -f "$SECRET_FILE" ]; then
        print_error "Archivo mongodb-secret.yaml no encontrado"
        exit 1
    fi

    # Extraer URI del archivo (simplificado, puede fallar con formato complejo)
    MONGODB_URI=$(grep "MONGODB_URI:" "$SECRET_FILE" | head -1 | cut -d'"' -f2)

    if [ -z "$MONGODB_URI" ] || [ "$MONGODB_URI" == "mongodb://host.docker.internal:27017" ]; then
        print_warning "URI de MongoDB parece ser la predeterminada"
        print_info "Asegúrate de haber configurado mongodb-secret.yaml con tus credenciales reales"

        read -p "¿Continuar de todas formas? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Abortando. Edita k8s/base/mongodb-secret.yaml y vuelve a ejecutar"
            exit 1
        fi
    else
        print_success "URI de MongoDB configurada: ${MONGODB_URI:0:30}..."
    fi
}

deploy_resources() {
    print_header "Desplegando Recursos en K8S"

    print_info "Namespace: $NAMESPACE"

    # Aplicar manifiestos con kustomize
    print_info "Aplicando manifiestos con kustomize..."
    if kubectl apply -k "$BASE_DIR" ; then
        print_success "Recursos aplicados correctamente"
    else
        print_error "Error al aplicar recursos"
        exit 1
    fi
}

wait_for_pods() {
    print_header "Esperando a que los Pods estén listos"

    print_info "Esperando a que langchain-api esté listo..."

    if kubectl wait --for=condition=ready pod \
        -l app=langchain-api \
        -n "$NAMESPACE" \
        --timeout=300s 2>/dev/null; then
        print_success "Pod langchain-api está listo"
    else
        print_warning "Timeout esperando a langchain-api. Verificando manualmente..."
        kubectl get pods -n "$NAMESPACE" -l app=langchain-api
    fi
}

verify_deployment() {
    print_header "Verificando Despliegue"

    # Ver todos los recursos
    print_info "Recursos en namespace $NAMESPACE:"
    kubectl get all,configmap,secret -n "$NAMESPACE"

    echo ""

    # Verificar variables de entorno
    print_info "Variables de entorno de MongoDB:"
    if kubectl exec -n "$NAMESPACE" deployment/langchain-api -- env | grep MONGODB; then
        print_success "Variables de entorno configuradas"
    else
        print_warning "No se pudieron obtener variables de entorno"
    fi

    echo ""

    # Ver logs recientes
    print_info "Últimas líneas de log de langchain-api:"
    kubectl logs -n "$NAMESPACE" -l app=langchain-api --tail=10 || true
}

test_mongodb_connection() {
    print_header "Probando Conexión a MongoDB"

    print_info "Ejecutando test de conexión..."

    if kubectl exec -n "$NAMESPACE" deployment/langchain-api -- \
        python /app/mcp_server/mongodb_mcp.py 2>&1 | tail -20; then
        print_success "Test de conexión ejecutado (revisa el output arriba)"
    else
        print_warning "Error ejecutando test. Revisa los logs"
    fi
}

show_next_steps() {
    print_header "Despliegue Completado"

    echo -e "${GREEN}"
    cat << 'EOF'
   ✓ MongoDB MCP desplegado en K3S

Próximos pasos:

1. Ver logs en tiempo real:
   kubectl logs -n llm-services -l app=langchain-api -f

2. Explorar tu base de datos:
   kubectl exec -n llm-services -it deployment/langchain-api -- \
     python /app/mcp_server/query_examples.py

3. Probar la API:
   kubectl port-forward -n llm-services svc/langchain-api 8000:8000
   # Luego en tu navegador: http://localhost:8000

4. Ver todos los recursos:
   kubectl get all -n llm-services

5. Ver documentación completa:
   cat k8s/K8S_MONGODB_DEPLOYMENT.md
EOF
    echo -e "${NC}"
}

###############################################################################
# Función principal
###############################################################################

main() {
    print_header "Despliegue de MongoDB MCP en K3S"

    check_prerequisites
    check_mongodb_secret
    deploy_resources
    wait_for_pods
    verify_deployment
    test_mongodb_connection
    show_next_steps

    print_success "¡Listo!"
}

###############################################################################
# Manejo de opciones
###############################################################################

show_help() {
    cat << EOF
Uso: $0 [OPCIÓN]

Despliega el servidor MCP de MongoDB en un cluster K3S.

Opciones:
    -h, --help              Mostrar esta ayuda
    -c, --check             Solo verificar requisitos previos
    -d, --deploy            Desplegar recursos (sin verificaciones previas)
    -v, --verify            Solo verificar el despliegue actual
    -t, --test              Solo ejecutar test de conexión
    --logs                  Ver logs en tiempo real
    --delete                Eliminar recursos del cluster

Ejemplos:
    $0                      Despliegue completo con verificaciones
    $0 --check              Solo verificar configuración
    $0 --logs               Ver logs en tiempo real
    $0 --delete             Eliminar todos los recursos

EOF
}

case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -c|--check)
        check_prerequisites
        check_mongodb_secret
        print_success "Todas las verificaciones pasaron"
        exit 0
        ;;
    -d|--deploy)
        deploy_resources
        wait_for_pods
        exit 0
        ;;
    -v|--verify)
        verify_deployment
        exit 0
        ;;
    -t|--test)
        test_mongodb_connection
        exit 0
        ;;
    --logs)
        print_info "Mostrando logs en tiempo real (Ctrl+C para salir)..."
        kubectl logs -n "$NAMESPACE" -l app=langchain-api -f
        exit 0
        ;;
    --delete)
        print_warning "Eliminando recursos de MongoDB MCP..."
        kubectl delete -k "$BASE_DIR" || true
        print_success "Recursos eliminados"
        exit 0
        ;;
    "")
        main
        exit 0
        ;;
    *)
        print_error "Opción desconocida: $1"
        show_help
        exit 1
        ;;
esac
