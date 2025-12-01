#!/usr/bin/env bash
set -euo pipefail

info() { echo -e "\e[36m$*\e[0m"; }
ok()   { echo -e "\e[32m$*\e[0m"; }
warn() { echo -e "\e[33m$*\e[0m"; }
err()  { echo -e "\e[31m$*\e[0m"; }

info "[1/6] Verificando Docker..."
if ! command -v docker >/dev/null 2>&1; then err "docker não encontrado no PATH"; exit 1; fi

info "[2/6] Build grpc-download-service (Python)..."
docker build -t zenildavieira/grpc-download-service:latest -f services/grpc/download/Dockerfile services/grpc/download

info "[3/6] Push grpc-download-service..."
docker push zenildavieira/grpc-download-service:latest

info "[4/6] Build grpc-playlist-service (Ruby)..."
docker build -t zenildavieira/grpc-playlist-service:latest -f services/grpc/playlist/Dockerfile services/grpc/playlist

info "[5/6] Push grpc-playlist-service..."
docker push zenildavieira/grpc-playlist-service:latest

info "[6/6] Reiniciando deployments no cluster..."
kubectl rollout restart deployment/grpc-download-deployment -n microservices
kubectl rollout restart deployment/grpc-playlist-deployment -n microservices

info "Aguardando rollouts..."
kubectl rollout status deployment/grpc-download-deployment -n microservices
kubectl rollout status deployment/grpc-playlist-deployment -n microservices

ok "Concluído. Sugestão: validar métricas com port-forward ou rodar scripts/resume.sh"
