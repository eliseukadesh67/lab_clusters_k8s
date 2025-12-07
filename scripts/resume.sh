#!/bin/bash

set -e

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

NAMESPACE_APP="microservices"
NAMESPACE_OBS="observability"
PF_DIR="./.pf"

# Parse argumentos
REBUILD=false
PORT_FORWARD=true
VALIDATE=true

for arg in "$@"; do
    case $arg in
        --rebuild)
            REBUILD=true
            ;;
        --no-port-forward)
            PORT_FORWARD=false
            ;;
        --no-validate)
            VALIDATE=false
            ;;
    esac
done

echo -e "${CYAN}🚀 Retomando ambiente de Observabilidade${NC}"

# --- VERIFICAÇÕES INICIAIS ---
echo -e "\n${CYAN}--- Verificando ferramentas necessárias ---${NC}"
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl não encontrado. Instale kubectl.${NC}"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo -e "${RED}docker não encontrado. Instale docker.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Ferramentas verificadas.${NC}"

# --- AGUARDAR KUBERNETES ---
echo -e "\n${CYAN}--- Aguardando Kubernetes ficar pronto ---${NC}"
timeout=60
elapsed=0
while ! kubectl get nodes &> /dev/null; do
    if [ $elapsed -ge $timeout ]; then
        echo -e "${RED}Kubernetes não ficou pronto em ${timeout}s.${NC}"
        exit 1
    fi
    echo "Aguardando..."
    sleep 2
    elapsed=$((elapsed + 2))
done
echo -e "${GREEN}✅ Kubernetes está pronto.${NC}"

# --- LISTAR PODS ---
echo -e "\n${CYAN}--- Pods em ${NAMESPACE_APP} ---${NC}"
kubectl get pods -n $NAMESPACE_APP

echo -e "\n${CYAN}--- Pods em ${NAMESPACE_OBS} ---${NC}"
kubectl get pods -n $NAMESPACE_OBS

# --- REBUILD (OPCIONAL) ---
if [ "$REBUILD" = true ]; then
    echo -e "\n${CYAN}--- Executando rebuild dos serviços gRPC ---${NC}"
    ./scripts/redeploy-grpc.sh
fi

# --- PORT FORWARDS ---
if [ "$PORT_FORWARD" = true ]; then
    echo -e "\n${CYAN}--- Iniciando port-forwards ---${NC}"
    
    mkdir -p $PF_DIR
    
    # Grafana
    echo "Port-forward: Grafana (3000)"
    kubectl -n $NAMESPACE_OBS port-forward svc/kube-prometheus-stack-grafana 3000:80 > $PF_DIR/grafana.log 2>&1 &
    echo $! > $PF_DIR/grafana.pid
    
    # Prometheus
    echo "Port-forward: Prometheus (9090)"
    kubectl -n $NAMESPACE_OBS port-forward svc/kube-prometheus-stack-prometheus 9090:9090 > $PF_DIR/prometheus.log 2>&1 &
    echo $! > $PF_DIR/prometheus.pid
    
    # gRPC Download Metrics
    echo "Port-forward: gRPC Download Metrics (19464)"
    kubectl -n $NAMESPACE_APP port-forward svc/grpc-download-service 19464:9464 > $PF_DIR/download-metrics.log 2>&1 &
    echo $! > $PF_DIR/download-metrics.pid
    
    # gRPC Playlist Metrics
    echo "Port-forward: gRPC Playlist Metrics (29464)"
    kubectl -n $NAMESPACE_APP port-forward svc/grpc-playlist-service 29464:9464 > $PF_DIR/playlist-metrics.log 2>&1 &
    echo $! > $PF_DIR/playlist-metrics.pid
    
    sleep 3
    echo -e "${GREEN}✅ Port-forwards iniciados.${NC}"
fi

# --- VALIDAÇÃO ---
if [ "$VALIDATE" = true ]; then
    echo -e "\n${CYAN}--- Validando exporters de métricas ---${NC}"
    
    sleep 2
    
    # Validar Download Metrics
    if curl -s http://localhost:19464/metrics > /dev/null; then
        echo -e "${GREEN}✅ Download metrics OK${NC}"
    else
        echo -e "${YELLOW}⚠️  Download metrics não respondeu${NC}"
    fi
    
    # Validar Playlist Metrics
    if curl -s http://localhost:29464/metrics > /dev/null; then
        echo -e "${GREEN}✅ Playlist metrics OK${NC}"
    else
        echo -e "${YELLOW}⚠️  Playlist metrics não respondeu${NC}"
    fi
    
    # Validar Prometheus Targets
    echo -e "\n${CYAN}--- Verificando targets no Prometheus ---${NC}"
    if curl -s http://localhost:9090/api/v1/targets | grep -q "grpc-download-service"; then
        echo -e "${GREEN}✅ Targets gRPC encontrados no Prometheus${NC}"
    else
        echo -e "${YELLOW}⚠️  Targets gRPC não encontrados (aguarde sync)${NC}"
    fi
fi

# --- RESULTADO ---
echo -e "\n${GREEN}🎉 Ambiente retomado com sucesso!${NC}"
echo -e "${YELLOW}📍 Acessos:${NC}"
echo -e "   Grafana: http://localhost:3000 (admin/prom-operator)"
echo -e "   Prometheus: http://localhost:9090"
echo -e "   Download Metrics: http://localhost:19464/metrics"
echo -e "   Playlist Metrics: http://localhost:29464/metrics"
echo ""
echo -e "${CYAN}Para parar port-forwards:${NC} ./scripts/stop-port-forwards.sh"
