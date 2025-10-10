#!/bin/bash

set -e

# Cores para o output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
K8S_MANIFESTS='k8s'

# --- PASSO 1: VERIFICAR DEPENDÊNCIAS ---
echo -e "${CYAN}--- PASSO 1: Verificando dependências ---${NC}"
DEPS=("docker" "kubectl" "minikube")
for dep in "${DEPS[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
        echo -e "${YELLOW}Dependência '$dep' não encontrada.${NC}"
        echo "Por favor, execute o script './install_deps.sh' para instalar as dependências necessárias."
        exit 1
    fi
done
echo -e "${GREEN}Todas as dependências estão instaladas.${NC}\n"

# --- PASSO 2: INICIAR O MINIKUBE ---
echo -e "${CYAN}--- PASSO 2: Iniciando o Minikube ---${NC}"
if ! minikube status | grep -q "host: Running"; then
    echo "Iniciando um novo cluster Minikube..."
    minikube start
else
    echo -e "${GREEN}Minikube já está em execução.${NC}"
fi
minikube addons enable ingress # Habilitar o addon de ingress é crucial
echo ""

# --- PASSO 3: CONFIGURAR AMBIENTE DOCKER ---
echo -e "${CYAN}--- PASSO 3: Apontando o Docker CLI para o daemon do Minikube ---${NC}"
eval $(minikube -p minikube docker-env)
echo -e "${GREEN}Ambiente configurado. As imagens serão construídas dentro do Minikube.${NC}\n"

# --- PASSO 4: MONTAR AS IMAGENS DOCKER ---
echo -e "${CYAN}--- PASSO 4: Construindo as imagens Docker dos microsserviços ---${NC}"

echo "Construindo imagem 'gateway-service:latest'..."
docker build -t gateway-service:latest -f ./gateway/Dockerfile .

echo "Construindo imagem 'grp-download-service:latest'..."
docker build -t grpc-download-service:latest ./services/grpc/download

echo "Construindo imagem 'grpc-playlist-service:latest'..."
docker build -t grpc-playlist-service:latest ./services/grpc/playlist

echo -e "${GREEN}Imagens construídas com sucesso!${NC}\n"

# --- PASSO 5: FAZER O DEPLOYMENT NO KUBERNETES ---
echo -e "${CYAN}--- PASSO 5: Aplicando os manifestos do Kubernetes ---${NC}"
# Extrai o namespace do arquivo namespace.yaml para uso futuro

echo "Verificando se o addon Ingress do Minikube está habilitado..."
if minikube addons list | grep 'ingress ' | grep -q 'enabled'; then
    echo -e "${GREEN}✅ Addon Ingress já está habilitado.${NC}"
else
    echo -e "${YELLOW}🚀 Habilitando o addon Ingress...${NC}"
    minikube addons enable ingress
    echo -e "${GREEN}✅ Addon Ingress habilitado com sucesso.${NC}"
fi

NAMESPACE="microservices"
echo "Garantindo que a criação do namespace '${NAMESPACE}'"
kubectl apply -f k8s/namespace.yaml
echo -e "${GREEN}✅ Namespace '${NAMESPACE}' aplicado.${NC}"

echo "Aplicando os deployments e services no namespace '$NAMESPACE'..."
kubectl apply -f $K8S_MANIFESTS
kubectl apply -f $K8S_MANIFESTS/grpc
echo -e "${GREEN}Deployments e Services aplicados.${NC}\n"

URL=$(minikube ip)

echo -e "\n${GREEN}🎉 SUCESSO! Sua aplicação está disponível em:${NC}"
echo -e "${YELLOW}>> http://${URL} <<${NC}\n"