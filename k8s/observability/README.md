# Instalação do Prometheus + Grafana (kube-prometheus-stack)

## Pré-requisitos:
- kubectl apontando para o cluster
- Helm instalado

## Comandos:

### 1) Adicionar o repositório e atualizar índices

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### 2) Criar namespace de observabilidade

```bash
kubectl create namespace observability
```

### 3) Instalar/atualizar a stack usando os valores deste diretório

```bash
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n observability \
  -f k8s/observability/values.yaml
```

### 4) Verificar Prometheus (port-forward)

```bash
kubectl -n observability port-forward svc/kube-prometheus-stack-prometheus 9090
# Abrir http://localhost:9090/targets para ver os ServiceMonitors dos serviços em microservices
```

### 5) Verificar Grafana

```bash
kubectl -n observability port-forward svc/kube-prometheus-stack-grafana 3000:80
# Abrir http://localhost:3000  (admin / prom-operator)
```

## Observação:
- Os ServiceMonitors em `k8s/observability/*` usam o label `release: kube-prometheus-stack`
- Os Services dos microserviços gRPC expõem métricas na porta `:9464/metrics`
- **Serviços monitorados**: apenas gRPC (gateway, download e playlist)

## Dashboards
- Aplique os dashboards para carregarem automaticamente no Grafana (sidecar):

```bash
kubectl apply -f k8s/observability/dashboard-grpc.yaml
```

- Depois, no Grafana, procure por "gRPC Services Overview".