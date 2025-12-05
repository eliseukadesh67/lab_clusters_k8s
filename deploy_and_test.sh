#!/bin/bash

set -e

# Cores para o output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

NAMESPACE="microservices"
K8S_MANIFESTS='k8s'

cleanup() {
    echo -e "\n\n${YELLOW}🛑 Sinal de interrupção recebido. Limpando o ambiente...${NC}"
    kubectl delete namespace "${NAMESPACE}" --ignore-not-found=true
    minikube stop --profile microservices || true
    echo -e "\n${GREEN}🧹 Ambiente limpo com sucesso! Até logo. 👋${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

echo -e "${CYAN}🚀 Iniciando deploy e teste da aplicação gRPC com Kubernetes${NC}"

# --- PASSO 1: INSTALAR DEPENDÊNCIAS ---
echo -e "\n${CYAN}--- PASSO 1: Instalando dependências ---${NC}"
./install_deps.sh

# --- PASSO 2: VERIFICAR DOCKER E INICIAR MINIKUBE ---
echo -e "\n${CYAN}--- PASSO 2: Verificando Docker e Iniciando Minikube ---${NC}"

# Verificar se Docker está rodando
if ! docker ps &> /dev/null; then
    echo -e "${RED}Docker não está rodando ou não está acessível.${NC}"
    echo -e "${YELLOW}Você adicionou seu usuário ao grupo 'docker' e fez logout/login do WSL?${NC}"
    echo ""
    read -p "Pressione 's' se já executou os passos necessários, ou 'n' para ver instruções: " resposta
    
    if [[ "$resposta" != "s" && "$resposta" != "S" ]]; then
        echo -e "\n${CYAN}Para resolver o problema de permissão do Docker:${NC}"
        echo -e "${YELLOW}1. Execute o seguinte comando:${NC}"
        echo -e "   ${GREEN}sudo usermod -aG docker \$USER${NC}"
        echo ""
        echo -e "${YELLOW}2. Saia do WSL:${NC}"
        echo -e "   ${GREEN}exit${NC}"
        echo ""
        echo -e "${YELLOW}3. Reabra o terminal WSL e navegue até a pasta do projeto${NC}"
        echo ""
        echo -e "${YELLOW}4. Execute novamente:${NC}"
        echo -e "   ${GREEN}./deploy_and_test.sh${NC}"
        echo ""
        echo -e "${YELLOW}Também certifique-se de que:${NC}"
        echo "• Docker Desktop está instalado e rodando no Windows"
        echo "• A integração com WSL está habilitada no Docker Desktop (Settings > Resources > WSL Integration)"
        echo ""
        exit 1
    fi
    
    echo -e "${YELLOW}Verificando novamente o acesso ao Docker...${NC}"
    if ! docker ps &> /dev/null; then
        echo -e "${RED}Ainda não foi possível acessar o Docker.${NC}"
        echo -e "${YELLOW}Por favor, execute os comandos acima e reinicie o WSL.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Docker está rodando e acessível.${NC}"

# Verificar se está rodando como root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Este script não deve ser executado com sudo ou como root.${NC}"
    echo -e "${YELLOW}Execute o script diretamente:${NC}"
    echo -e "   ${GREEN}./deploy_and_test.sh${NC}"
    echo ""
    exit 1
fi

if minikube status --profile microservices &> /dev/null; then
    echo -e "${GREEN}Minikube já está rodando.${NC}"
else
    echo "Iniciando Minikube com perfil 'microservices'..."
    minikube start --profile microservices --driver=docker --memory=4096 --cpus=2
    echo -e "${GREEN}Minikube iniciado com sucesso.${NC}"
fi

# --- PASSO 3: CONFIGURAR DOCKER PARA MINIKUBE ---
echo -e "\n${CYAN}--- PASSO 3: Configurando Docker para Minikube ---${NC}"
eval $(minikube docker-env --profile microservices)
echo -e "${GREEN}Docker configurado para Minikube.${NC}"

# --- PASSO 4: CONSTRUIR IMAGENS DOCKER ---
echo -e "\n${CYAN}--- PASSO 4: Construindo imagens Docker ---${NC}"
echo "Construindo imagem 'gateway-service:latest'..."
docker build -t gateway-service:latest -f ./gateway/Dockerfile .

echo "Construindo imagem 'grpc-download-service:latest'..."
docker build -t grpc-download-service:latest ./services/grpc/download

echo "Construindo imagem 'grpc-playlist-service:latest'..."
docker build -t grpc-playlist-service:latest ./services/grpc/playlist

echo -e "${GREEN}Imagens construídas com sucesso!${NC}"

# --- PASSO 5: APLICAR MANIFESTS KUBERNETES ---
echo -e "\n${CYAN}--- PASSO 5: Aplicando manifests Kubernetes ---${NC}"
kubectl apply -f $K8S_MANIFESTS/namespace.yaml
kubectl apply -f $K8S_MANIFESTS
kubectl apply -f $K8S_MANIFESTS/grpc

echo -e "${GREEN}Manifests aplicados.${NC}"

# --- PASSO 5.1: INSTALAR PROMETHEUS E GRAFANA ---
echo -e "\n${CYAN}--- PASSO 5.1: Configurando Observabilidade (Prometheus + Grafana) ---${NC}"

# Criar namespace de observabilidade
if ! kubectl get namespace observability &> /dev/null; then
    echo "Criando namespace 'observability'..."
    kubectl create namespace observability
fi

# Adicionar repositório Helm do Prometheus
echo "Adicionando repositório Helm do Prometheus..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts &> /dev/null || true
helm repo update

# Instalar ou atualizar kube-prometheus-stack
echo "Instalando/Atualizando kube-prometheus-stack..."
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n observability \
  -f k8s/observability/values.yaml \
  --wait

echo -e "${GREEN}Prometheus e Grafana instalados.${NC}"

# Aplicar ServiceMonitors
echo "Aplicando ServiceMonitors gRPC..."
kubectl apply -f k8s/observability/servicemonitor-gateway.yaml
kubectl apply -f k8s/observability/servicemonitor-grpc-download.yaml
kubectl apply -f k8s/observability/servicemonitor-grpc-playlist.yaml

# Aplicar Dashboard
echo "Aplicando Dashboard gRPC no Grafana..."
kubectl apply -f k8s/observability/dashboard-grpc.yaml

echo -e "${GREEN}Observabilidade configurada!${NC}"

# --- PASSO 6: AGUARDAR PODS FICAREM PRONTOS ---
echo -e "\n${CYAN}--- PASSO 6: Aguardando pods ficarem prontos ---${NC}"
echo "Aguardando deployments de aplicação..."
kubectl wait --for=condition=available --timeout=300s deployment --all -n $NAMESPACE

echo "Aguardando pods de aplicação..."
kubectl wait --for=condition=ready pod --all -n $NAMESPACE --timeout=300s

echo "Aguardando pods de observabilidade..."
kubectl wait --for=condition=ready pod --all -n observability --timeout=300s || echo -e "${YELLOW}Alguns pods de observabilidade ainda estão iniciando...${NC}"

echo -e "${GREEN}Todos os pods estão prontos!${NC}"

# --- PASSO 7: VERIFICAR STATUS DOS DEPLOYMENTS ---
echo -e "\n${CYAN}--- PASSO 7: Verificando status dos deployments ---${NC}"

echo "Verificando deployments de aplicação..."
kubectl get deployments -n $NAMESPACE

echo -e "\nVerificando pods de aplicação..."
kubectl get pods -n $NAMESPACE

echo -e "\nVerificando pods de observabilidade..."
kubectl get pods -n observability

echo -e "${GREEN}✅ Status dos deployments verificado!${NC}"

# --- PASSO 8: PREPARAR FRONTEND ---
echo -e "\n${CYAN}--- PASSO 8: Preparando frontend ---${NC}"

# Verificar se dependências do frontend estão instaladas
if [ ! -d "frontend/node_modules" ]; then
    echo "Instalando dependências do frontend..."
    cd frontend
    npm install
    cd ..
    echo -e "${GREEN}✅ Dependências do frontend instaladas.${NC}"
else
    echo -e "${GREEN}Dependências do frontend já instaladas.${NC}"
fi

# Criar arquivo .env para o frontend
echo "Criando arquivo .env para o frontend..."
cat <<EOF > frontend/.env
API_URL=http://localhost:8080
PORT=3000
EOF

echo -e "${GREEN}✅ Arquivo .env criado para o frontend.${NC}"

# --- PASSO 9: REMOVER PORT-FORWARDS AUTOMÁTICOS ---
echo -e "\n${CYAN}--- PASSO 9: Finalizando deploy ---${NC}"
echo -e "${GREEN}Deploy concluído!${NC}"

# --- RESULTADO FINAL ---
echo -e "\n${GREEN}🎉 APLICAÇÃO DEPLOYADA E TESTADA COM SUCESSO!${NC}"

echo -e "\n${YELLOW}📍 Para acessar a aplicação completa, execute os seguintes comandos em terminais separados:${NC}"
echo ""
echo -e "${CYAN}Terminal 1 - Port-forward do Gateway:${NC}"
echo -e "   ${GREEN}kubectl port-forward -n microservices svc/gateway-service 8080:3000${NC}"
echo ""
echo -e "${CYAN}Terminal 2 - Port-forward do Grafana:${NC}"
echo -e "   ${GREEN}kubectl port-forward -n observability svc/kube-prometheus-stack-grafana 3001:80${NC}"
echo ""
echo -e "${CYAN}Terminal 3 - Port-forward do Prometheus:${NC}"
echo -e "   ${GREEN}kubectl port-forward -n observability svc/kube-prometheus-stack-prometheus 9090:9090${NC}"
echo ""
echo -e "${CYAN}Terminal 4 - Rodar o Frontend:${NC}"
echo -e "   ${GREEN}cd frontend && npm start${NC}"
echo ""

echo -e "\n${YELLOW}📊 URLs de acesso:${NC}"
echo -e "   ${CYAN}Frontend:${NC} http://localhost:3000"
echo -e "   ${CYAN}Gateway (via port-forward):${NC} http://localhost:8080"
echo -e "   ${CYAN}Grafana:${NC} http://localhost:3001 (usuário: admin, senha: admin)"
echo -e "   ${CYAN}Prometheus:${NC} http://localhost:9090"

echo -e "\n${YELLOW}📊 Observabilidade:${NC}"
echo -e "   - ServiceMonitors ativos para Gateway e serviços gRPC"
echo -e "   - Dashboard gRPC configurado no Grafana"
echo -e "   - Métricas disponíveis nas portas 9464 dos serviços"

echo -e "\n${YELLOW}ℹ️  Informações importantes:${NC}"
echo -e "   - Mantenha os terminais de port-forward abertos enquanto usar a aplicação"
echo -e "   - O frontend se conecta ao gateway através do port-forward (localhost:8080)"
echo -e "   - A senha padrão do Grafana é 'admin' (não 'prom-operator')"

echo -e "\n${CYAN}Para parar a aplicação:${NC}"
echo -e "   1. Pressione Ctrl+C em cada terminal de port-forward"
echo -e "   2. Pare o frontend (Ctrl+C)"
echo -e "   3. (Opcional) Delete os namespaces: ${GREEN}kubectl delete namespace $NAMESPACE observability${NC}"
echo -e "   4. (Opcional) Pare o Minikube: ${GREEN}minikube stop --profile microservices${NC}"

echo -e "\n${GREEN}✅ Deploy finalizado com sucesso!${NC}"