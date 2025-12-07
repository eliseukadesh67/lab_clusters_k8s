#!/bin/bash

set -e

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

NAMESPACE="microservices"
DOCKER_USER="eliseukadesh67"  # Altere para seu usuário Docker Hub

echo -e "${CYAN}🔄 Rebuild e Redeploy dos serviços gRPC${NC}"

# --- BUILD E PUSH ---
echo -e "\n${CYAN}--- Building imagens Docker ---${NC}"

# Download Service
echo "Building grpc-download-service..."
docker build -t $DOCKER_USER/grpc-download-service:latest ./services/grpc/download

# Playlist Service
echo "Building grpc-playlist-service..."
docker build -t $DOCKER_USER/grpc-playlist-service:latest ./services/grpc/playlist

echo -e "${GREEN}✅ Imagens construídas.${NC}"

# PUSH (opcional, se estiver usando registry)
read -p "Fazer push para Docker Hub? (s/n): " push_choice
if [[ "$push_choice" == "s" || "$push_choice" == "S" ]]; then
    echo -e "\n${CYAN}--- Pushing imagens ---${NC}"
    docker push $DOCKER_USER/grpc-download-service:latest
    docker push $DOCKER_USER/grpc-playlist-service:latest
    echo -e "${GREEN}✅ Imagens enviadas.${NC}"
fi

# --- RESTART DEPLOYMENTS ---
echo -e "\n${CYAN}--- Reiniciando deployments ---${NC}"

kubectl rollout restart deployment/grpc-download-deployment -n $NAMESPACE
kubectl rollout restart deployment/grpc-playlist-deployment -n $NAMESPACE

echo "Aguardando rollout..."
kubectl rollout status deployment/grpc-download-deployment -n $NAMESPACE
kubectl rollout status deployment/grpc-playlist-deployment -n $NAMESPACE

echo -e "${GREEN}✅ Deployments reiniciados.${NC}"
