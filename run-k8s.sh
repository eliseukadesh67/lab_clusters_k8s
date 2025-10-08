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

echo "Construindo imagem 'download-service:latest'..."
docker build -t download-service:latest ./services/download

echo "Construindo imagem 'playlist-service:latest'..."
docker build -t playlist-service:latest ./services/playlist

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

echo "Garantindo a existência do Secret do Ngrok ..."
# Verifica se a variável de ambiente NGROK_AUTHTOKEN está definida
if [ -z "$NGROK_AUTHTOKEN" ]; then
    echo -e "${YELLOW}⚠️ ERRO: A variável de ambiente NGROK_AUTHTOKEN não está definida.${NC}"
    echo "Por favor, defina-a com o seu token e tente novamente:"
    echo "export NGROK_AUTHTOKEN=\"seu_token_aqui\""
    exit 1
fi

SECRET_NAME="ngrok-secret"

kubectl create secret generic ${SECRET_NAME} \
  --namespace=${NAMESPACE} \
  --from-literal=NGROK_AUTHTOKEN=${NGROK_AUTHTOKEN} \
  --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✅ Secret '${SECRET_NAME}' configurado no namespace '${NAMESPACE}'.${NC}"

echo "Aplicando os deployments e services no namespace '$NAMESPACE'..."
kubectl apply -f $K8S_MANIFESTS
echo -e "${GREEN}Deployments e Services aplicados.${NC}\n"

# --- PASSO 6: MOSTRAR URL DO NGROK ---
echo -e "${CYAN}--- PASSO 6: Aguardando a URL pública do Ngrok ---${NC}"

echo "Verificando se o pod do Ngrok está em execução..."
# Espera o pod ser criado e obter um nome.
while [ -z "$(kubectl get pods -n $NAMESPACE -l app=ngrok -o jsonpath='{.items[0].metadata.name}')" ]; do
  echo -n "."
  sleep 2
done

NGROK_POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=ngrok -o jsonpath='{.items[0].metadata.name}')
echo -e "\nPod do Ngrok (${NGROK_POD_NAME}) encontrado. Buscando URL nos logs..."

URL=""

for i in {1..30}; do
  URL=$(kubectl logs -n $NAMESPACE $NGROK_POD_NAME | grep -o 'url=[^ ]*' | head -n 1 | cut -d'=' -f2)

  if [ ! -z "$URL" ]; then
    break
  fi
  echo -n "."
  sleep 2
done

echo "" # Pula uma linha

# Verifica se a URL foi encontrada
if [ ! -z "$URL" ]; then
  echo -e "\n${GREEN}🎉 SUCESSO! Sua aplicação está disponível em:${NC}"
  echo -e "${YELLOW}>> ${URL} <<${NC}\n"
else
  echo -e "\n${YELLOW}⚠️ ERRO: Não foi possível obter a URL do ngrok após 60 segundos.${NC}"
  echo "Mostrando os logs do pod '${NGROK_POD_NAME}' para diagnóstico:"
  echo "----------------------------------------------------"
  kubectl logs -n $NAMESPACE $NGROK_POD_NAME --tail=20
  echo "----------------------------------------------------"
  exit 1
fi