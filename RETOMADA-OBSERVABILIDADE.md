# Guia de Retomada do Ambiente de Observabilidade

Este guia explica como retomar o ambiente (Prometheus/Grafana + serviços gRPC) após reiniciar o computador. Inclui comandos de retomada, acessos rápidos, como parar os port-forwards e dicas de troubleshooting.

## Pré-requisitos ao religar o PC
- **WSL (Linux)**: Usuário normal (não root), Docker Desktop integrado com WSL
- **Windows**: Docker Desktop com status "Kubernetes is running"
- Contexto `kubectl` configurado para o cluster local
- Na raiz do repositório `lab_clusters_k8s`

## O que os scripts fazem
- **`scripts/resume.sh` (Linux)** / **`scripts/resume.ps1` (Windows)**:
  - Verifica ferramentas (`kubectl`, `docker`) e aguarda o Kubernetes ficar pronto.
  - Lista os pods dos namespaces `microservices` e `observability`.
  - (Opcional) Reconstrói e publica imagens dos serviços gRPC e reinicia os deployments.
  - Inicia port-forwards em background:
    - Grafana: `localhost:3000`
    - Prometheus: `localhost:9090`
    - Métricas gRPC Download: `localhost:19464`
    - Métricas gRPC Playlist: `localhost:29464`
  - (Opcional) Valida exporters de métricas e targets gRPC no Prometheus.

## Comandos de retomada

### Linux (WSL)
Execute na raiz do repo (`lab_clusters_k8s`).

```bash
# Retomar com port-forwards + validação (SEM rebuild por padrão)
./scripts/resume.sh

# Retomar e REBUILDAR/PUSH das imagens gRPC antes de validar
./scripts/resume.sh --rebuild

# Retomar sem abrir port-forwards e sem rodar validação
./scripts/resume.sh --no-port-forward --no-validate
```

### Windows (PowerShell)
Execute na raiz do repo (`lab_clusters_k8s`).

```powershell
# Retomar com port-forwards + validação (SEM rebuild por padrão)
.\scripts\resume.ps1

# Retomar e REBUILDAR/PUSH das imagens gRPC antes de validar
.\scripts\resume.ps1 -Rebuild

# Retomar sem abrir port-forwards e sem rodar validação
.\scripts\resume.ps1 -PortForward:$false -Validate:$false
```

## Acessos rápidos
- Grafana: `http://localhost:3000`
- Prometheus: `http://localhost:9090`
- Métricas gRPC (via port-forward):
  - Download: `http://localhost:19464/metrics`
  - Playlist: `http://localhost:29464/metrics`

## Parar port-forwards

### Linux (WSL)
```bash
./scripts/stop-port-forwards.sh
```

### Windows (PowerShell)
Os port-forwards rodam como Jobs do PowerShell. Pare-os com:

```powershell
Get-Job
Get-Job | Stop-Job -Force
Get-Job | Remove-Job
```

Se algum port-forward ficar "preso", feche o terminal que iniciou os Jobs.

## Redeploy manual dos serviços gRPC

### Linux (WSL)
```bash
./scripts/redeploy-grpc.sh
```

### Windows (PowerShell)
```powershell
.\scripts\redeploy-grpc.ps1
```

O script faz build/push das imagens e reinicia os deployments gRPC.

### Checagens rápidas
```powershell
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
  - Aguarde alguns segundos após o rollout; valide os logs do pod/deployment.
  - Garanta que o redeploy foi executado (imagens atualizadas) — rode `scripts/redeploy-grpc.ps1`.
  - Tente port-forward para o Service (como no script) em vez do Pod diretamente.
- “Prometheus API falhou”: verifique se o port-forward para Prometheus está ativo (`localhost:9090`).
- “Kubernetes não está pronto”: aguarde o Docker Desktop iniciar o cluster.
- Firewalls/Antivírus podem bloquear port-forwards; teste desativar temporariamente se necessário.

## Boas práticas antes de desligar
```powershell
# Salvar e versionar alterações
git add -A
git commit -m "Docs: guia de retomada; scripts de retomada e redeploy"
git push origin feature/prometheus-observability

# (Opcional) Parar port-forwards
Get-Job | Stop-Job -Force; Get-Job | Remove-Job

# (Opcional) Economizar recursos escalando a zero
kubectl -n microservices scale deploy --all --replicas=0
# Para retomar, basta rodar o redeploy ou escalar de volta
```

## Arquivos relevantes
- `scripts/resume.ps1` — script principal de retomada.
- `scripts/redeploy-grpc.ps1` — build/push e rollout dos serviços gRPC.
- `k8s/` — manifests de Kubernetes (apps e observability).

---

