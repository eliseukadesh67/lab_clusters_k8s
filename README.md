# Projeto de Microsserviços com gRPC, Kubernetes e Observabilidade

Este projeto é uma demonstração completa de uma arquitetura de microsserviços poliglota usando gRPC, projetada para ser executada localmente com Docker e Kubernetes (via Minikube), incluindo stack completa de observabilidade com Prometheus e Grafana.

O objetivo principal é explorar o protocolo de comunicação **gRPC** (para comunicação de alta performance) e práticas de monitoramento em ambientes distribuídos. A aplicação consiste em um frontend, um API Gateway e dois serviços de backend, cada um implementado em uma linguagem diferente.

## 🏛️ Arquitetura

A aplicação segue um padrão clássico de API Gateway, onde o cliente (frontend) se comunica apenas com o gateway, que por sua vez orquestra as chamadas para os microsserviços internos.

### ✨ Tecnologias Utilizadas
* **Frontend**: Node.js, Express, EJS
* **API Gateway**: Node.js, Express
* **Serviço de Playlist**: Ruby (com gRPC-Ruby)
* **Serviço de Download**: Python (com gRPC-Python)
* **Comunicação**: gRPC (com Protocol Buffers)
* **Containerização**: Docker
* **Orquestração**: Kubernetes (Minikube)
* **Observabilidade**: Prometheus + Grafana (kube-prometheus-stack)

## 🚀 Como Executar o Projeto

### Opção 1: Deploy Automático com Observabilidade (Recomendado)

Para executar tudo com um único comando (instalação, deploy, observabilidade e testes), use o script automatizado:

```bash
./deploy_and_test.sh
```

Este script irá:
- Instalar todas as dependências necessárias (Docker, kubectl, Minikube, Node.js, Helm)
- Iniciar o Minikube com o perfil "microservices"
- Construir as imagens Docker localmente
- Aplicar os manifests Kubernetes para a aplicação
- **Instalar Prometheus e Grafana** (kube-prometheus-stack)
- **Configurar ServiceMonitors** para coletar métricas dos serviços gRPC
- **Aplicar Dashboard** customizado para gRPC no Grafana
- Aguardar os serviços ficarem prontos
- Testar a aplicação automaticamente
- Preparar o frontend
- **Iniciar port-forwards** para Grafana e Prometheus

**URLs de Acesso após deploy:**
- Gateway: `http://<MINIKUBE_IP>`
- Frontend: `http://localhost:3000` (após executar `cd frontend && npm start`)
- **Grafana**: `http://localhost:3001` (usuário: `admin`, senha: `prom-operator`)
- **Prometheus**: `http://localhost:9090`

### Opção 2: Passos Manuais

Siga os passos abaixo para configurar e executar toda a aplicação em sua máquina local.

#### 1. Pré-requisitos

O ambiente foi projetado para sistemas Linux (baseados em Debian/Ubuntu) ou WSL no Windows. O script de instalação cuidará das seguintes dependências:
* Docker
* kubectl
* Minikube
* Node.js e npm
* Helm

#### 2. Passos para a Execução

1.  **Clone o Repositório**
    ```bash
    git clone <URL_DO_SEU_REPOSITORIO>
    cd <NOME_DA_PASTA_DO_PROJETO>
    ```

2.  **Dê Permissão de Execução aos Scripts**
    É um passo crucial para que o terminal possa executar os arquivos.
    ```bash
    chmod +x *.sh
    ```

3.  **Instale as Dependências do Ambiente**
    Este script irá verificar e instalar Docker, Minikube, kubectl e Node.js na sua máquina.
    ```bash
    ./install_deps.sh
    ```
    > **Nota**: A instalação do Docker pode exigir que você faça logout e login novamente para aplicar as permissões do usuário.

4.  **Execute a Aplicação com Kubernetes**
    Este é o script principal. Ele irá automatizar todo o processo:
    * Iniciar o cluster Minikube.
    * Apontar o Docker local para o ambiente do Minikube.
    * Construir as imagens Docker de cada microsserviço.
    * Aplicar os manifestos do Kubernetes para criar os deployments e services.
    * Instalar as dependências e iniciar o frontend.

    ```bash
    ./run.sh
    ```

### 3. Acessando a Aplicação

* Após o script `deploy_and_test.sh` ser executado com sucesso, o **API Gateway** estará disponível no IP do Minikube. O script irá imprimir as URLs no final, algo como:
    > **Gateway: http://192.168.49.2** (o IP pode variar)

* Para acessar o **frontend**, execute em outro terminal:
    ```bash
    cd frontend && npm start
    ```
    E acesse em: **http://localhost:3000**

## 📊 Observabilidade e Monitoramento

Este projeto inclui uma stack completa de observabilidade com Prometheus e Grafana, configurada automaticamente pelo script de deploy.

### 🎯 O que foi Configurado

1. **Prometheus**: Coleta de métricas dos serviços gRPC
   - ServiceMonitors configurados para Gateway, Playlist e Download services
   - Métricas expostas na porta 9464 de cada serviço
   - Acesso via `http://localhost:9090`

2. **Grafana**: Visualização de métricas e dashboards
   - Dashboard customizado para gRPC configurado automaticamente
   - Acesso via `http://localhost:3001`
   - Credenciais: usuário `admin`, senha `prom-operator`

3. **ServiceMonitors**: 
   - `servicemonitor-gateway.yaml`: Monitora métricas do API Gateway
   - `servicemonitor-grpc-download.yaml`: Monitora serviço de Download (Python)
   - `servicemonitor-grpc-playlist.yaml`: Monitora serviço de Playlist (Ruby)

4. **Dashboard gRPC**: Painel customizado com:
   - Taxa de requisições gRPC por serviço
   - Latência (p50, p95, p99)
   - Taxa de erros
   - Uso de recursos (CPU, memória)

### 🔄 Scripts de Observabilidade

Para ambientes onde você já executou o deploy anteriormente e quer apenas retomar a observabilidade:

```bash
# Retomar observabilidade (Prometheus + Grafana)
./scripts/resume.sh

# Reconstruir e fazer redeploy apenas dos serviços gRPC
./scripts/redeploy-grpc.sh

# Parar todos os port-forwards ativos
./scripts/stop-port-forwards.sh
```

### 4. Parando e Limpando o Ambiente

Para parar a aplicação e remover todos os componentes criados (containers, deployments, etc.), basta pressionar `Ctrl+C` no terminal onde o `deploy_and_test.sh` está sendo executado.

O script irá capturar o sinal e executar uma rotina de limpeza automática, parando os port-forwards, o Minikube e deletando todos os recursos do Kubernetes.

Como alternativa, execute manualmente:
```bash
kubectl delete namespace microservices observability
minikube stop --profile microservices
```

## 🚀 Início Rápido

Após reiniciar o computador:

```bash
# 1. Abrir WSL e navegar para o projeto
cd /mnt/c/Users/Zenilda/OneDrive/Documentos/@_@FGA/wsGitHub/2025-2_PSPD_lab_cluster_k8s/lab_clusters_k8s

# 2. Deploy automático completo
./deploy_and_test.sh
```

**Deixe esse terminal aberto!** Ele mantém Minikube e port-forwards ativos.

### Iniciar Frontend (Novo Terminal)

```bash
cd frontend
npm start
```

### URLs de Acesso

| Serviço | URL | Credenciais |
|---------|-----|-------------|
| Gateway | `http://<MINIKUBE_IP>` | - |
| Frontend | `http://localhost:3000` | - |
| Grafana | `http://localhost:3001` | admin / prom-operator |
| Prometheus | `http://localhost:9090` | - |

## 📋 Checklist de Deploy

Use este checklist sempre que executar a aplicação:

### Pré-Requisitos
- [ ] Docker Desktop rodando no Windows
- [ ] WSL aberto e funcionando
- [ ] Diretório correto do projeto

### Passos do Deploy
- [ ] Executar `./deploy_and_test.sh`
- [ ] Verificar instalação de dependências
- [ ] Confirmar Minikube iniciado
- [ ] Aguardar build das imagens Docker
- [ ] Verificar deploy dos manifests K8s
- [ ] Confirmar instalação Prometheus/Grafana
- [ ] Aguardar pods prontos
- [ ] Verificar testes automáticos ✅

### Verificações Finais
- [ ] Gateway acessível
- [ ] Frontend funcionando (criar playlist)
- [ ] Grafana acessível e com dashboard
- [ ] Prometheus coletando métricas

## 🛠️ Comandos Rápidos

### Status dos Pods
```bash
kubectl get pods -n microservices
kubectl get pods -n observability
```

### Logs de um Pod
```bash
kubectl logs <nome-do-pod> -n microservices -f
```

### Executar Comando em Pod
```bash
kubectl exec -it <nome-do-pod> -n microservices -- /bin/bash
```

### Reiniciar Deployment
```bash
kubectl rollout restart deployment/<nome> -n microservices
```

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

## 🐛 Troubleshooting

### Docker não conecta
- Abra Docker Desktop
- Settings → Resources → WSL Integration → Ativar Ubuntu
- Reinicie WSL: `wsl --shutdown`

### Port-forward parou
```bash
./scripts/resume.sh
```

### Pods não prontos
```bash
kubectl describe pod <nome-do-pod> -n microservices
kubectl logs <nome-do-pod> -n microservices
```

### Minikube não inicia
```bash
minikube delete --profile microservices
./deploy_and_test.sh
```

## 🗂️ Estrutura do Projeto

<details>
<summary>Clique para ver a árvore de diretórios</summary>

```
.
├── frontend
│   ├── app.js
│   ├── package.json
│   └── views
├── gateway
│   ├── clients
│   ├── controllers
│   ├── Dockerfile
│   └── server.js
├── install_deps.sh
├── k8s
│   ├── gateway-deployment.yaml
│   ├── gateway-ingress.yaml
│   ├── grpc
│   ├── observability
│   └── namespace.yaml
├── proto
│   ├── download.proto
│   └── playlist.proto
├── README.md
├── run.sh
└── services
    ├── grpc
    │   ├── download (Python)
    │   └── playlist (Ruby)
```

</details>