#!/usr/bin/env bash
set -euo pipefail

REBUILD=false
PORT_FORWARD=true
VALIDATE=true

info() { echo -e "\e[36m$*\e[0m"; }
ok()   { echo -e "\e[32m$*\e[0m"; }
warn() { echo -e "\e[33m$*\e[0m"; }
err()  { echo -e "\e[31m$*\e[0m"; }

usage() {
  cat <<EOF
Uso: scripts/resume.sh [opções]
  --rebuild           Rebuild/push imagens gRPC e restart deployments
  --no-port-forward   Não abrir port-forwards
  --no-validate       Não executar validações automáticas
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rebuild) REBUILD=true; shift ;;
    --no-port-forward) PORT_FORWARD=false; shift ;;
    --no-validate) VALIDATE=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Opção desconhecida: $1"; usage; exit 1 ;;
  esac
done

info "[1/7] Verificando ferramentas (kubectl, docker)..."
if ! command -v kubectl >/dev/null 2>&1; then err "kubectl não encontrado"; exit 1; fi
if ! command -v docker >/dev/null 2>&1; then warn "docker não encontrado (rebuild será ignorado)"; REBUILD=false; fi

info "[2/7] Verificando Kubernetes..."
READY=false
for i in {1..20}; do
  if kubectl get nodes --no-headers >/dev/null 2>&1; then READY=true; break; fi
  sleep 3
done
$READY || { err "Kubernetes não está pronto. Inicie seu cluster (Docker Desktop, kind, minikube, etc.)."; exit 1; }
ok "Kubernetes OK."

info "[3/7] Namespaces e pods principais..."
kubectl get ns microservices observability || true
kubectl get pods -n microservices || true
kubectl get pods -n observability || true

if $REBUILD; then
  info "[4/7] Rebuild + push imagens e restart deployments (gRPC)..."
  bash "$(dirname "$0")/redeploy-grpc.sh"
else
  warn "Pulando rebuild. Use --rebuild para reconstruir e publicar imagens."
fi

info "[5/7] Iniciando port-forwards (opcional)..."
if $PORT_FORWARD; then
  mkdir -p .pf
  # Grafana 3000->80
  kubectl -n observability port-forward svc/kube-prometheus-stack-grafana 3000:80 > ./.pf/grafana.log 2>&1 & echo $! > ./.pf/grafana.pid
  # Prometheus 9090->9090
  kubectl -n observability port-forward svc/kube-prometheus-stack-prometheus 9090:9090 > ./.pf/prometheus.log 2>&1 & echo $! > ./.pf/prometheus.pid
  # Métricas gRPC
  kubectl -n microservices port-forward svc/grpc-download-service 19464:9464 > ./.pf/grpc-download.log 2>&1 & echo $! > ./.pf/grpc-download.pid
  kubectl -n microservices port-forward svc/grpc-playlist-service 29464:9464 > ./.pf/grpc-playlist.log 2>&1 & echo $! > ./.pf/grpc-playlist.pid
  ok "Port-forwards iniciados. PIDs em ./.pf/*.pid"
  warn "Para parar: scripts/stop-port-forwards.sh"
else
  warn "Pulando port-forward. Use --no-port-forward para desativar."
fi

info "[6/7] Validação básica (opcional)..."
if $VALIDATE; then
  sleep 3
  # Testar métricas gRPC
  if command -v curl >/dev/null 2>&1; then
    set +e
    D=$(curl -s -o /tmp/metrics_d -w "%{http_code}" http://localhost:19464/metrics); RC=$?
    if [[ $RC -eq 0 && $D =~ ^2 ]]; then ok "grpc-download metrics: HTTP $D ($(wc -c </tmp/metrics_d) bytes)"; else err "grpc-download metrics falhou (HTTP $D)"; fi
    P=$(curl -s -o /tmp/metrics_p -w "%{http_code}" http://localhost:29464/metrics); RC=$?
    if [[ $RC -eq 0 && $P =~ ^2 ]]; then ok "grpc-playlist metrics: HTTP $P ($(wc -c </tmp/metrics_p) bytes)"; else err "grpc-playlist metrics falhou (HTTP $P)"; fi
    # Prometheus targets
    T=$(curl -s http://localhost:9090/api/v1/targets?state=any)
    if [[ -n "$T" ]]; then
      echo "$T" | grep -E "grpc-(download|playlist)-service" -q && ok "Targets gRPC encontrados no Prometheus (verifique UI)." || warn "Não identifiquei targets gRPC na resposta."
    else
      err "Prometheus API não respondeu. Port-forward ativo?"
    fi
    set -e
  else
    warn "curl não encontrado, pulando validação"
  fi
else
  warn "Pulando validação. Use --no-validate para desativar."
fi

info "[7/7] Pronto! Acesse:"
echo "- Grafana:     http://localhost:3000"
echo "- Prometheus:  http://localhost:9090"
echo "- gRPC metrics: http://localhost:19464/metrics (download)"
echo "- gRPC metrics: http://localhost:29464/metrics (playlist)"

ok "Finalizado."
