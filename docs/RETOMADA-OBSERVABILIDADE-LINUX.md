# Guia de Retomada do Ambiente de Observabilidade (Linux)

Este guia descreve como retomar rapidamente o ambiente de Observabilidade (Prometheus/Grafana + microserviços) em Linux, utilizando os scripts bash adicionados ao projeto. Inclui pré-requisitos, comandos de retomada, acessos rápidos, parada de port-forwards, redeploy manual, checagens e troubleshooting.

## Visão Geral
- Scripts principais (bash):
  - `scripts/resume.sh`: retoma o ambiente (port-forwards, validações e, opcionalmente, rebuild/push + rollout dos serviços gRPC).
  - `scripts/redeploy-grpc.sh`: rebuild/push das imagens gRPC e reinício dos deployments.
  - `scripts/stop-port-forwards.sh`: encerra os port-forwards iniciados pelo `resume.sh`.
- Serviços expostos localmente via port-forward:
  - Grafana: `http://localhost:3000`
  - Prometheus: `http://localhost:9090`
  - Exporters gRPC:
    - Download: `http://localhost:19464/metrics`
    - Playlist: `http://localhost:29464/metrics`

## Pré-requisitos ao religar
- Cluster Kubernetes (uma das opções):
  - Docker Desktop (Linux) com Kubernetes habilitado, ou
  - kind (recomendado para desenvolvimento local), ou
  - minikube, ou
  - microk8s.
- `kubectl` instalado e configurado para o cluster ativo.
- `docker` instalado (para rebuild/push de imagens, se necessário).
- `helm` instalado (caso precise reinstalar kube-prometheus-stack).

Exemplo com kind:
```bash
kind create cluster --name observability || true
kubectl cluster-info
```

Instalação do Helm (se necessário):
```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

## Scripts e o que fazem
- `scripts/resume.sh`:
  - Verifica `kubectl`/`docker`, aguarda Kubernetes ficar pronto e lista pods de `microservices` e `observability`.
  - Opção `--rebuild`: executa `scripts/redeploy-grpc.sh` (rebuild/push + rollout dos gRPCs).
  - Abre port-forwards para Grafana (3000), Prometheus (9090) e exporters gRPC (19464/29464) em background (PIDs em `./.pf/*.pid`).
  - Valida exporters (`/metrics`) e consulta a API de targets do Prometheus.
- `scripts/redeploy-grpc.sh`:
  - `docker build` e `docker push` de `zenildavieira/grpc-download-service:latest` e `zenildavieira/grpc-playlist-service:latest`.
  - `kubectl rollout restart` dos deployments gRPC e `kubectl rollout status` para aguardar.
- `scripts/stop-port-forwards.sh`:
  - Lê PIDs em `./.pf/*.pid`, finaliza os processos dos port-forwards e remove arquivos `.pid`/`.log`.

## Comandos de retomada (Linux)
Execute na raiz do repositório `lab_clusters_k8s`.

```bash
# Tornar scripts executáveis (uma vez)
chmod +x scripts/*.sh

# 1) Retomar com port-forwards + validação (SEM rebuild por padrão)
./scripts/resume.sh

# 2) Retomar e REBUILDAR/PUSH das imagens gRPC antes de validar
./scripts/resume.sh --rebuild

# 3) Retomar sem abrir port-forwards e sem rodar validação
./scripts/resume.sh --no-port-forward --no-validate
```

## Acessos rápidos
- Grafana: `http://localhost:3000`
- Prometheus: `http://localhost:9090`
- Métricas gRPC:
  - Download: `http://localhost:19464/metrics`
  - Playlist: `http://localhost:29464/metrics`

## Parar port-forwards
```bash
./scripts/stop-port-forwards.sh
```
Caso o script não esteja disponível, matar os processos listados em `./.pf/*.pid` também funciona (`kill <PID>`).

## Redeploy manual dos gRPC
```bash
./scripts/redeploy-grpc.sh
```
Esse script faz build/push das imagens e reinicia os deployments gRPC.

## Checagens rápidas
```bash
# Kubernetes
kubectl get nodes
kubectl get pods -n microservices
kubectl get pods -n observability

# Logs dos services gRPC
kubectl logs -n microservices deploy/grpc-download-deployment
kubectl logs -n microservices deploy/grpc-playlist-deployment

# Port-forward de um serviço específico (ex.: download metrics)
kubectl -n microservices port-forward svc/grpc-download-service 19464:9464
curl http://localhost:19464/metrics
```

## Troubleshooting
- “Connection refused” no `/metrics`:
  - Aguarde alguns segundos após o rollout; confira os logs do pod/deployment.
  - Rode `./scripts/redeploy-grpc.sh` para garantir imagens atualizadas.
  - Prefira port-forward do Service (como acima) em vez do Pod.
- “Prometheus API falhou” ao usar o `resume.sh`:
  - Verifique se o port-forward para Prometheus está ativo (`localhost:9090`).
- “Kubernetes não está pronto”:
  - Inicie seu cluster (Docker Desktop, kind, minikube, microk8s) e aguarde o `kubectl get nodes` responder.
- Firewalls/Antivírus:
  - Podem bloquear port-forwards; teste desativar temporariamente para validar.
- Docker login:
  - Para rebuild/push: `docker login` (se necessário).

## Boas práticas antes de desligar
```bash
# Salvar e versionar alterações
git add -A
git commit -m "Docs Linux: retomada; scripts resume/redeploy/stop-pf"
git push origin feature/prometheus-observabilidade

# Parar port-forwards
./scripts/stop-port-forwards.sh

# (Opcional) Economizar recursos escalando a zero
kubectl -n microservices scale deploy --all --replicas=0
# Para retomar, execute o resume.sh ou faça o redeploy
```

## Arquivos relevantes
- `scripts/resume.sh` — retomada no Linux.
- `scripts/redeploy-grpc.sh` — rebuild/push e rollout dos gRPC no Linux.
- `scripts/stop-port-forwards.sh` — encerra os port-forwards do `resume.sh`.
- `docs/RETOMADA-OBSERVABILIDADE.md` — guia geral com seção Windows/PowerShell e Linux.
- `k8s/` — manifests de Kubernetes (apps e observability).
