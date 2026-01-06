#!/bin/bash
# Script de configuración para Raspberry Pi 5
# Descarga los modelos necesarios y verifica la instalación

set -e  # Salir si hay errores

echo "======================================================"
echo "   Configuración de LangChain + Ollama para RPI 5   "
echo "======================================================"
echo ""

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Verificar que Docker está instalado
echo "1. Verificando Docker..."
if ! command -v docker &> /dev/null; then
    print_error "Docker no está instalado. Por favor instala Docker primero."
    echo "   Ejecuta: curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh"
    exit 1
fi
print_success "Docker está instalado"

# Verificar que Docker Compose está disponible
echo "2. Verificando Docker Compose..."
if ! docker compose version &> /dev/null; then
    print_error "Docker Compose no está disponible"
    exit 1
fi
print_success "Docker Compose está disponible"

# Verificar arquitectura
echo "3. Verificando arquitectura del sistema..."
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "arm64" ]; then
    print_warning "Este script está optimizado para ARM64 (Raspberry Pi)"
    print_warning "Tu arquitectura es: $ARCH"
    read -p "¿Continuar de todos modos? (s/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
else
    print_success "Arquitectura ARM64 detectada"
fi

# Mostrar información del sistema
echo "4. Información del sistema:"
echo "   - RAM total: $(free -h | awk '/^Mem:/ {print $2}')"
echo "   - RAM disponible: $(free -h | awk '/^Mem:/ {print $7}')"
echo "   - Espacio en disco: $(df -h / | awk 'NR==2 {print $4}') disponibles"
echo ""

# Verificar espacio en disco (necesitamos al menos 10GB)
AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
if [ $AVAILABLE_SPACE -lt 10485760 ]; then  # 10GB en KB
    print_warning "Espacio en disco bajo. Se recomienda al menos 10GB libres."
fi

# Copiar archivo .env si no existe
echo "5. Configurando variables de entorno..."
if [ ! -f .env ]; then
    if [ -f .env.rpi ]; then
        cp .env.rpi .env
        print_success "Archivo .env creado desde .env.rpi"
    else
        cp .env.example .env
        print_warning "Archivo .env creado desde .env.example"
        print_warning "Considera usar .env.rpi para Raspberry Pi"
    fi
else
    print_success "Archivo .env ya existe"
fi

# Iniciar servicios con docker-compose
echo ""
echo "6. Iniciando servicios Docker..."
docker compose -f docker-compose.rpi.yml up -d

echo ""
print_success "Servicios Docker iniciados"

# Esperar a que Ollama esté listo
echo ""
echo "7. Esperando a que Ollama esté listo..."
MAX_ATTEMPTS=30
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if docker exec ollama-server curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        print_success "Ollama está listo"
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    echo -n "."
    sleep 2
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    print_error "Ollama no responde después de $MAX_ATTEMPTS intentos"
    print_warning "Verifica los logs: docker compose -f docker-compose.rpi.yml logs ollama"
    exit 1
fi

# Menú de selección de modelo
echo ""
echo "8. Selección de modelo LLM:"
echo "   Elige el modelo que deseas descargar (optimizado para 8GB RAM):"
echo ""
echo "   1) gemma2:2b (Recomendado) - 2.7GB - Modelo de Google, excelente calidad"
echo "   2) phi3:mini - 2.3GB - Modelo de Microsoft, muy eficiente"
echo "   3) llama3.2:3b - 2GB - Versión ligera de Meta Llama"
echo "   4) tinyllama - 600MB - Ultra ligero, para pruebas"
echo "   5) Omitir descarga (hacerlo manualmente después)"
echo ""
read -p "Selecciona una opción (1-5): " MODEL_CHOICE

case $MODEL_CHOICE in
    1)
        MODEL="gemma2:2b"
        ;;
    2)
        MODEL="phi3:mini"
        ;;
    3)
        MODEL="llama3.2:3b"
        ;;
    4)
        MODEL="tinyllama"
        ;;
    5)
        print_warning "Descarga de modelo omitida"
        MODEL=""
        ;;
    *)
        print_warning "Opción inválida, usando gemma2:2b por defecto"
        MODEL="gemma2:2b"
        ;;
esac

# Descargar modelo principal
if [ -n "$MODEL" ]; then
    echo ""
    echo "9. Descargando modelo $MODEL..."
    print_warning "Esta operación puede tardar varios minutos dependiendo de tu conexión..."

    if docker exec ollama-server ollama pull $MODEL; then
        print_success "Modelo $MODEL descargado correctamente"
    else
        print_error "Error al descargar el modelo $MODEL"
        print_warning "Puedes descargarlo manualmente: docker exec ollama-server ollama pull $MODEL"
    fi
else
    echo "9. Descarga de modelo omitida"
fi

# Descargar modelo de embeddings
echo ""
echo "10. Descargando modelo de embeddings (para RAG)..."
if docker exec ollama-server ollama pull nomic-embed-text; then
    print_success "Modelo nomic-embed-text descargado correctamente"
else
    print_warning "Error al descargar nomic-embed-text (opcional para RAG)"
fi

# Verificar modelos instalados
echo ""
echo "11. Modelos instalados:"
docker exec ollama-server ollama list

# Mostrar instrucciones finales
echo ""
echo "======================================================"
print_success "Instalación completada!"
echo "======================================================"
echo ""
echo "Próximos pasos:"
echo ""
echo "1. Verificar que todo funciona:"
echo "   docker exec -it langchain-app python main.py"
echo ""
echo "2. Ejecutar ejemplos de RAG:"
echo "   docker exec -it langchain-app python rag_example.py"
echo ""
echo "3. Iniciar la API web:"
echo "   docker compose -f docker-compose.rpi.yml restart langchain-app"
echo "   docker compose -f docker-compose.rpi.yml exec langchain-app python api_server.py"
echo "   Luego visita: http://localhost:8000"
echo ""
echo "4. Ver logs en tiempo real:"
echo "   docker compose -f docker-compose.rpi.yml logs -f"
echo ""
echo "5. Monitorear recursos:"
echo "   docker stats"
echo ""
echo "6. Detener servicios:"
echo "   docker compose -f docker-compose.rpi.yml down"
echo ""
echo "Documentación completa en: RASPBERRY_PI_SETUP.md"
echo ""
print_success "¡Disfruta de tu LLM local en Raspberry Pi! 🚀"
echo ""
