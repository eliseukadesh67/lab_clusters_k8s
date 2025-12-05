# ✅ Checklist de Deploy - Aplicação gRPC + Kubernetes

Use este checklist sempre que for executar a aplicação após reiniciar o computador.

## Pré-Requisitos (Antes de Começar)

- [ ] Docker Desktop está **rodando** no Windows
- [ ] WSL está aberto e funcionando
- [ ] Você está no diretório do projeto:
  ```bash
  cd /mnt/c/Users/Zenilda/OneDrive/Documentos/@_@FGA/wsGitHub/2025-2_PSPD_lab_cluster_k8s/lab_clusters_k8s
  ```

## Passo 1: Deploy Automático

- [ ] Execute o script de deploy:
  ```bash
  ./deploy_and_test.sh
  ```

### O que Esperar:

- [ ] **PASSO 1**: Instalação de dependências (se necessário)
- [ ] **PASSO 2**: Docker verificado e Minikube iniciado
- [ ] **PASSO 3**: Imagens Docker construídas (pode demorar ~5-10 min)
- [ ] **PASSO 4**: Variáveis de ambiente configuradas
- [ ] **PASSO 5**: Manifests Kubernetes aplicados
- [ ] **PASSO 5.1**: Prometheus e Grafana instalados
- [ ] **PASSO 6**: Todos os pods prontos (pode demorar ~2-5 min)
- [ ] **PASSO 7**: Testes automáticos executados com sucesso ✅
- [ ] **PASSO 8**: Frontend preparado
- [ ] **PASSO 9**: Port-forwards iniciados

### Mensagem Final Esperada:

```
🎉 APLICAÇÃO DEPLOYADA E TESTADA COM SUCESSO!
📍 URLs de acesso:
   Gateway: http://<MINIKUBE_IP>
   Frontend: Execute 'cd frontend && npm start' e acesse http://localhost:3000
   Grafana: http://localhost:3001 (usuário: admin, senha: prom-operator)
   Prometheus: http://localhost:9090
```

- [ ] Mensagem de sucesso apareceu
- [ ] Anote o IP do Minikube: `___________________________`

## Passo 2: Iniciar Frontend (Terminal Separado)

- [ ] Abra um **NOVO terminal WSL**
- [ ] Navegue até o diretório do frontend:
  ```bash
  cd /mnt/c/Users/Zenilda/OneDrive/Documentos/@_@FGA/wsGitHub/2025-2_PSPD_lab_cluster_k8s/lab_clusters_k8s/frontend
  ```
- [ ] Inicie o servidor frontend:
  ```bash
  npm start
  ```
- [ ] Frontend rodando na porta 3000

## Passo 3: Verificar Acessos

### Aplicação
- [ ] Gateway respondendo: `http://<MINIKUBE_IP>` (use o IP anotado)
- [ ] Frontend acessível: `http://localhost:3000`
- [ ] Consegue criar uma playlist no frontend
- [ ] Consegue adicionar uma música à playlist

### Observabilidade
- [ ] Grafana acessível: `http://localhost:3001`
- [ ] Login no Grafana com: `admin` / `prom-operator`
- [ ] Dashboard "gRPC Services" está disponível
- [ ] Prometheus acessível: `http://localhost:9090`
- [ ] Consegue ver métricas no Prometheus (ex: `up`)

## Passo 4: Verificações de Saúde

### Pods da Aplicação
```bash
kubectl get pods -n microservices
```
- [ ] `gateway-...` está **Running** e **READY 1/1**
- [ ] `grpc-download-...` está **Running** e **READY 1/1**
- [ ] `grpc-playlist-...` está **Running** e **READY 1/1**

### Pods de Observabilidade
```bash
kubectl get pods -n observability
```
- [ ] `kube-prometheus-stack-grafana-...` está **Running**
- [ ] `prometheus-kube-prometheus-stack-prometheus-0` está **Running**
- [ ] `kube-prometheus-stack-operator-...` está **Running**

## Passo 5: Teste Funcional Completo

### Teste de Playlist
- [ ] Acesse o frontend: `http://localhost:3000`
- [ ] Clique em "Criar Nova Playlist"
- [ ] Digite um nome e crie a playlist
- [ ] Playlist aparece na lista
- [ ] Abra a playlist criada
- [ ] Adicione uma URL de vídeo do YouTube
- [ ] Vídeo é adicionado com título e thumbnail

### Verificar Métricas
- [ ] Acesse Grafana: `http://localhost:3001`
- [ ] Vá em Dashboards → "gRPC Services"
- [ ] Veja métricas de requisições aumentarem
- [ ] Verifique latência dos serviços
- [ ] Confirme que não há erros

## Troubleshooting Rápido

### ❌ Se algo der errado, consulte:

| Problema | Comando de Verificação | Solução |
|----------|------------------------|---------|
| Docker não conecta | `docker ps` | Abra Docker Desktop |
| Pods não prontos | `kubectl get pods -A` | Aguarde mais tempo ou veja logs |
| Port-forward parou | `ps aux \| grep kubectl` | Execute `./scripts/resume.sh` |
| Minikube não inicia | `minikube status` | Execute `minikube delete --profile microservices` |

### 🔧 Comandos Úteis

```bash
# Ver logs de um pod específico
kubectl logs <nome-do-pod> -n microservices

# Ver todos os serviços
kubectl get svc -n microservices

# Reiniciar observabilidade
./scripts/resume.sh

# Parar tudo e limpar
# (Ctrl+C no terminal do deploy_and_test.sh)
kubectl delete namespace microservices observability
minikube stop --profile microservices
```

## 🎉 Checklist de Sucesso Final

Se você marcou ✅ em todos os itens abaixo, está tudo funcionando:

- [ ] ✅ Deploy automático completou sem erros
- [ ] ✅ Frontend está acessível e funcionando
- [ ] ✅ Consegue criar e gerenciar playlists
- [ ] ✅ Grafana está acessível e mostrando métricas
- [ ] ✅ Prometheus está coletando dados
- [ ] ✅ Todos os pods estão em estado Running
- [ ] ✅ Port-forwards estão ativos

---

**Data do último deploy:** _______________  
**Tempo total:** ___________ minutos  
**Problemas encontrados:** 
- _______________________________________________________
- _______________________________________________________

**Notas:**
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

