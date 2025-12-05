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

# --- PASSO 7: TESTAR A APLICAÇÃO ---
echo -e "\n${CYAN}--- PASSO 7: Testando a aplicação ---${NC}"

# Obter IP do Minikube
MINIKUBE_IP=$(minikube ip --profile microservices)

# Testar gateway
echo "Testando Gateway..."
if curl -s "http://${MINIKUBE_IP}/playlists" > /dev/null; then
    echo -e "${GREEN}✅ Gateway respondendo em http://${MINIKUBE_IP}${NC}"
else
    echo -e "${RED}❌ Gateway não respondeu${NC}"
    exit 1
fi

# Testar playlist service via gateway
echo "Testando Playlist Service..."
if curl -s -X POST "http://${MINIKUBE_IP}/playlists" -H "Content-Type: application/json" -d '{"name":"Test Playlist"}' | grep -q "Playlist criada"; then
    echo -e "${GREEN}✅ Playlist Service funcionando${NC}"
else
    echo -e "${RED}❌ Playlist Service falhou${NC}"
    exit 1
fi

# Testar download service via gateway (metadata)
echo "Testando Download Service..."
if curl -s "http://${MINIKUBE_IP}/metadata?url=https://www.youtube.com/watch?v=dQw4w9WgXcQ" | grep -q "title"; then
    echo -e "${GREEN}✅ Download Service funcionando${NC}"
else
    echo -e "${RED}❌ Download Service falhou${NC}"
    exit 1
fi

# --- PASSO 8: INICIAR FRONTEND ---
echo -e "\n${CYAN}--- PASSO 8: Preparando frontend ---${NC}"
cd frontend
npm install
echo "Frontend instalado."

# Criar .env
cat <<EOF > .env
API_URL=http://${MINIKUBE_IP}
PORT=3000
EOF

echo -e "${GREEN}✅ .env criado para frontend.${NC}"
cd ..

# --- PASSO 9: CONFIGURAR PORT-FORWARDS PARA OBSERVABILIDADE ---
echo -e "\n${CYAN}--- PASSO 9: Iniciando port-forwards para Grafana e Prometheus ---${NC}"

# Criar diretório para PIDs
mkdir -p .pf

# Função para limpar port-forwards ao sair
cleanup() {
    echo -e "\n${YELLOW}Parando port-forwards...${NC}"
    pkill -P $$ kubectl 2>/dev/null
    rm -rf .pf
    echo -e "${GREEN}Port-forwards encerrados.${NC}"
}
trap cleanup EXIT INT TERM

# Aguardar serviço do Grafana estar pronto
echo "Aguardando serviço do Grafana..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n observability --timeout=120s || true

# Aguardar serviço do Prometheus estar pronto
echo "Aguardando serviço do Prometheus..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n observability --timeout=120s || true

# Iniciar port-forward para Grafana (porta 3001 para evitar conflito com frontend na 3000)
echo "Iniciando port-forward para Grafana (porta 3001)..."
kubectl port-forward -n observability svc/kube-prometheus-stack-grafana 3001:80 > .pf/grafana.log 2>&1 &
GRAFANA_PID=$!
echo $GRAFANA_PID > .pf/grafana.pid
sleep 2

# Iniciar port-forward para Prometheus (porta 9090)
echo "Iniciando port-forward para Prometheus (porta 9090)..."
kubectl port-forward -n observability svc/kube-prometheus-stack-prometheus 9090:9090 > .pf/prometheus.log 2>&1 &
PROMETHEUS_PID=$!
echo $PROMETHEUS_PID > .pf/prometheus.pid
sleep 2

echo -e "${GREEN}Port-forwards configurados!${NC}"

# --- RESULTADO FINAL ---
echo -e "\n${GREEN}🎉 APLICAÇÃO DEPLOYADA E TESTADA COM SUCESSO!${NC}"
echo -e "${YELLOW}📍 URLs de acesso:${NC}"
echo -e "   ${CYAN}Gateway:${NC} http://${MINIKUBE_IP}"
echo -e "   ${CYAN}Frontend:${NC} Execute 'cd frontend && npm start' e acesse http://localhost:3000"
echo -e "   ${CYAN}Grafana:${NC} http://localhost:3001 (usuário: admin, senha: prom-operator)"
echo -e "   ${CYAN}Prometheus:${NC} http://localhost:9090"

echo -e "\n${YELLOW}📊 Observabilidade:${NC}"
echo -e "   - ServiceMonitors ativos para Gateway e serviços gRPC"
echo -e "   - Dashboard gRPC configurado no Grafana"
echo -e "   - Métricas disponíveis nas portas 9464 dos serviços"

echo -e "\n${CYAN}Para parar a aplicação:${NC}"
echo -e "   Pressione Ctrl+C ou execute: kubectl delete namespace $NAMESPACE observability && minikube stop --profile microservices"

# Manter o script rodando para manter Minikube e port-forwards ativos
echo -e "\n${YELLOW}Mantendo Minikube e port-forwards ativos. Pressione Ctrl+C para parar.${NC}"
while true; do
    sleep 60
    # Verificar se port-forwards ainda estão ativos
    if ! ps -p $GRAFANA_PID > /dev/null 2>&1; then
        echo -e "${YELLOW}Reiniciando port-forward do Grafana...${NC}"
        kubectl port-forward -n observability svc/kube-prometheus-stack-grafana 3001:80 > .pf/grafana.log 2>&1 &
        GRAFANA_PID=$!
        echo $GRAFANA_PID > .pf/grafana.pid
    fi
    if ! ps -p $PROMETHEUS_PID > /dev/null 2>&1; then
        echo -e "${YELLOW}Reiniciando port-forward do Prometheus...${NC}"
        kubectl port-forward -n observability svc/kube-prometheus-stack-prometheus 9090:9090 > .pf/prometheus.log 2>&1 &
        PROMETHEUS_PID=$!
        echo $PROMETHEUS_PID > .pf/prometheus.pid
    fi
done