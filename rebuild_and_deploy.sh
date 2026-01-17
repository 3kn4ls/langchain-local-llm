#!/bin/bash

# ======================================================
#   Rebuild and Deploy: LangChain Local LLM (Linux)
# ======================================================

echo "Stopping current containers..."
docker-compose down

echo "Building and starting services..."
docker-compose up -d --build

echo ""
echo "Deployment finished!"
echo ""
echo "Check status with: docker-compose ps"
echo "API logs: docker-compose logs -f langchain-api"
echo "Frontend URL: http://localhost:3000"
echo "======================================================"
