# 🚀 Início Rápido - Aplicação com gRPC + Kubernetes + Observabilidade

Este documento contém tudo que você precisa saber para executar a aplicação completa após reiniciar seu computador.

## ⚡ Comando Único para Deploy Completo

Depois de reiniciar o computador e abrir o VS Code no WSL:

```bash
./deploy_and_test.sh
```

**Esse comando faz TUDO automaticamente:**
- ✅ Verifica e instala dependências (Docker, kubectl, Minikube, Node.js, Helm)
- ✅ Inicia o Minikube com o perfil "microservices"
- ✅ Constrói todas as imagens Docker localmente
- ✅ Faz deploy da aplicação (Gateway, Playlist Service, Download Service)
- ✅ Instala Prometheus e Grafana para observabilidade
- ✅ Configura ServiceMonitors para métricas gRPC
- ✅ Aplica Dashboard customizado no Grafana
- ✅ Testa se tudo está funcionando
- ✅ Prepara o frontend
- ✅ Inicia port-forwards para Grafana e Prometheus

## 🌐 URLs de Acesso

Após o deploy bem-sucedido, você terá acesso a:

| Serviço | URL | Credenciais |
|---------|-----|-------------|
| **Gateway** | `http://<MINIKUBE_IP>` | - |
| **Frontend** | `http://localhost:3000` | - |
| **Grafana** | `http://localhost:3001` | admin / prom-operator |
| **Prometheus** | `http://localhost:9090` | - |

> **Nota:** O `<MINIKUBE_IP>` será exibido ao final da execução do script.

## 🎯 Para Iniciar o Frontend

Após o script terminar, abra um novo terminal e execute:

```bash
cd frontend
npm start
```

Acesse `http://localhost:3000` no navegador.

## 📊 Acessando as Métricas

### Grafana (Dashboards)
1. Acesse `http://localhost:3001`
2. Login: `admin` / `prom-operator`
3. Vá em "Dashboards" → Procure por "gRPC Services"
4. Visualize métricas de latência, taxa de requisições, erros, etc.

### Prometheus (Métricas Raw)
1. Acesse `http://localhost:9090`
2. Use a barra de pesquisa para consultar métricas
3. Exemplos de queries:
   - `rate(grpc_server_handled_total[5m])` - Taxa de requisições gRPC
   - `histogram_quantile(0.95, grpc_server_handling_seconds_bucket)` - Latência p95

## 🛠️ Scripts Auxiliares

### Retomar Apenas Observabilidade
Se você já tem a aplicação rodando e quer apenas reiniciar Prometheus/Grafana:

```bash
./scripts/resume.sh
```

### Reconstruir Serviços gRPC
Para reconstruir e fazer redeploy apenas dos serviços gRPC (após alterações no código):

```bash
./scripts/redeploy-grpc.sh
```

### Parar Port-Forwards
Para parar todos os port-forwards ativos:

```bash
./scripts/stop-port-forwards.sh
```

## 🔄 Fluxo Completo de Trabalho

### 1. Após Reiniciar o Computador

```bash
# Abrir WSL e navegar para o projeto
cd /mnt/c/Users/Zenilda/OneDrive/Documentos/@_@FGA/wsGitHub/2025-2_PSPD_lab_cluster_k8s/lab_clusters_k8s

# Executar deploy completo
./deploy_and_test.sh
```

### 2. Quando o Deploy Terminar

O script ficará rodando e mostrará periodicamente que o Minikube está ativo. **Deixe esse terminal aberto!**

### 3. Abrir Novo Terminal para Frontend

```bash
cd frontend
npm start
```

### 4. Testar a Aplicação

- Acesse o frontend: `http://localhost:3000`
- Crie playlists, adicione músicas
- Veja as métricas no Grafana: `http://localhost:3001`

### 5. Para Parar Tudo

No terminal onde `deploy_and_test.sh` está rodando, pressione `Ctrl+C`.

O script irá automaticamente:
- Parar todos os port-forwards
- Parar o Minikube
- Limpar recursos

## 🐛 Troubleshooting

### Docker não está rodando
**Problema:** Erro "Cannot connect to the Docker daemon"

**Solução:**
1. Abra Docker Desktop no Windows
2. Vá em Settings → Resources → WSL Integration
3. Ative a integração com sua distribuição Ubuntu
4. Reinicie o WSL: `wsl --shutdown` no PowerShell, depois abra novamente

### Port-forward parou de funcionar
**Problema:** Grafana ou Prometheus não acessível

**Solução:** 
O script reinicia automaticamente os port-forwards a cada 60 segundos. Se ainda assim não funcionar:
```bash
./scripts/resume.sh
```

### Pods não estão prontos
**Problema:** Deploy trava em "Aguardando pods ficarem prontos"

**Solução:**
```bash
# Verificar status dos pods
kubectl get pods -n microservices
kubectl get pods -n observability

# Ver logs de um pod específico
kubectl logs <nome-do-pod> -n microservices
```

### Minikube não inicia
**Problema:** Erro ao iniciar Minikube

**Solução:**
```bash
# Deletar o perfil e começar do zero
minikube delete --profile microservices

# Executar o script novamente
./deploy_and_test.sh
```

## 📝 Notas Importantes

1. **Docker Desktop deve estar rodando** antes de executar o script
2. **Primeira execução demora mais** (download de imagens base, instalação de dependências)
3. **Deixe o terminal do script aberto** enquanto usa a aplicação (mantém Minikube e port-forwards ativos)
4. **Frontend roda separadamente** - precisa de um segundo terminal
5. **Credenciais do Grafana:** admin / prom-operator (sempre as mesmas)

## 🎓 Recursos Adicionais

- **README.md** - Documentação completa do projeto
- **services/README.md** - Detalhes sobre os serviços gRPC
- **RETOMADA-OBSERVABILIDADE-GRPC-ONLY.md** - Guia detalhado de observabilidade
- **k8s/observability/** - Manifests de ServiceMonitors e Dashboards

---

**Dica:** Adicione este documento aos favoritos do seu navegador ou crie um atalho para acesso rápido! 🚀
