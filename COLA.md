# 🚀 COLA - Comandos Rápidos

## 📌 Deploy Completo (Após Reiniciar)

```bash
# 1. Abrir WSL e ir para o projeto
cd /mnt/c/Users/Zenilda/OneDrive/Documentos/@_@FGA/wsGitHub/2025-2_PSPD_lab_cluster_k8s/lab_clusters_k8s

# 2. Deploy automático
./deploy_and_test.sh
```

**Deixe esse terminal aberto!** Ele mantém Minikube e port-forwards ativos.

---

## 🌐 URLs de Acesso

```
Gateway:     http://<MINIKUBE_IP>
Frontend:    http://localhost:3000
Grafana:     http://localhost:3001    (admin / prom-operator)
Prometheus:  http://localhost:9090
```

---

## 🎯 Iniciar Frontend (Novo Terminal)

```bash
cd /mnt/c/Users/Zenilda/OneDrive/Documentos/@_@FGA/wsGitHub/2025-2_PSPD_lab_cluster_k8s/lab_clusters_k8s/frontend
npm start
```

---

## 🛠️ Comandos Úteis

### Ver Status dos Pods
```bash
kubectl get pods -n microservices
kubectl get pods -n observability
```

### Ver Logs de um Pod
```bash
kubectl logs <nome-do-pod> -n microservices
kubectl logs <nome-do-pod> -n microservices -f  # follow/acompanhar
```

### Ver Todos os Serviços
```bash
kubectl get svc -n microservices
kubectl get svc -n observability
```

### Executar Comando em um Pod
```bash
kubectl exec -it <nome-do-pod> -n microservices -- /bin/bash
```

### Reiniciar um Deployment
```bash
kubectl rollout restart deployment/<nome> -n microservices
```

---

## 🔄 Scripts Auxiliares

### Retomar Observabilidade
```bash
./scripts/resume.sh
```

### Reconstruir Serviços gRPC
```bash
./scripts/redeploy-grpc.sh
```

### Parar Port-Forwards
```bash
./scripts/stop-port-forwards.sh
```

---

## 🧹 Limpeza e Parada

### Parar Tudo (Método 1 - Recomendado)
No terminal onde `deploy_and_test.sh` está rodando:
```
Ctrl+C
```

### Parar Tudo (Método 2 - Manual)
```bash
kubectl delete namespace microservices observability
minikube stop --profile microservices
```

### Deletar Completamente o Minikube
```bash
minikube delete --profile microservices
```

---

## 🔍 Troubleshooting

### Docker não conecta
```bash
# No Windows PowerShell
wsl --shutdown

# Abrir Docker Desktop
# Settings → Resources → WSL Integration → Ativar sua distro
# Reabrir WSL
```

### Verificar Docker no WSL
```bash
docker ps
docker version
```

### Verificar Minikube
```bash
minikube status --profile microservices
minikube ip --profile microservices
```

### Port-forward parou
```bash
./scripts/resume.sh
```

### Pods não ficam prontos
```bash
# Ver o que está errado
kubectl describe pod <nome-do-pod> -n microservices

# Ver eventos do namespace
kubectl get events -n microservices --sort-by='.lastTimestamp'
```

---

## 📊 Queries Úteis no Prometheus

```promql
# Taxa de requisições gRPC
rate(grpc_server_handled_total[5m])

# Latência p95
histogram_quantile(0.95, grpc_server_handling_seconds_bucket)

# Taxa de erros
rate(grpc_server_handled_total{grpc_code!="OK"}[5m])

# Requisições por método
sum(rate(grpc_server_started_total[5m])) by (grpc_method)
```

---

## 🎓 Navegação Grafana

1. Login: `admin` / `prom-operator`
2. Dashboards → Browse
3. Procure "gRPC Services"
4. Explore os painéis:
   - Request Rate
   - Latency
   - Error Rate
   - Resource Usage

---

## ⚡ Atalhos de Teclado (WSL)

```
Ctrl+C       Parar processo atual
Ctrl+D       Sair do terminal
Ctrl+L       Limpar tela
Ctrl+R       Buscar comando no histórico
Ctrl+Z       Suspender processo
Tab          Autocompletar
```

---

## 📁 Estrutura de Pastas Importante

```
.
├── deploy_and_test.sh          ← Script principal
├── install_deps.sh             ← Instala dependências
├── INICIO-RAPIDO.md            ← Guia de início rápido
├── CHECKLIST-DEPLOY.md         ← Checklist de deploy
├── frontend/                   ← Aplicação web
├── gateway/                    ← API Gateway (Node.js)
├── services/grpc/              ← Serviços gRPC
│   ├── download/               ← Python
│   └── playlist/               ← Ruby
├── k8s/                        ← Manifests Kubernetes
│   ├── grpc/                   ← Deployments e Services gRPC
│   └── observability/          ← ServiceMonitors e Dashboard
└── scripts/                    ← Scripts auxiliares
    ├── resume.sh
    ├── redeploy-grpc.sh
    └── stop-port-forwards.sh
```

---

**💡 Dica:** Salve este arquivo como favorito para acesso rápido! 

**🔗 Links Úteis:**
- Kubernetes Docs: https://kubernetes.io/docs/
- Prometheus Docs: https://prometheus.io/docs/
- Grafana Docs: https://grafana.com/docs/
- gRPC Docs: https://grpc.io/docs/
