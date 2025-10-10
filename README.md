# Projeto de Microsserviços: gRPC vs REST com Kubernetes

Este projeto é uma demonstração completa de uma arquitetura de microsserviços poliglota, projetada para ser executada localmente com Docker e Kubernetes (via Minikube).

O objetivo principal é explorar e comparar dois protocolos de comunicação populares: **gRPC** (para comunicação de alta performance) e **REST** (o padrão da web). A aplicação consiste em um frontend, um API Gateway e dois serviços de backend, cada um implementado em uma linguagem diferente.

## 🏛️ Arquitetura

A aplicação segue um padrão clássico de API Gateway, onde o cliente (frontend) se comunica apenas com o gateway, que por sua vez orquestra as chamadas para os microsserviços internos.

### ✨ Tecnologias Utilizadas
* **Frontend**: Node.js, Express, EJS
* **API Gateway**: Node.js, Express
* **Serviço de Playlist**: Ruby (com gRPC-Ruby e Sinatra para REST)
* **Serviço de Download**: Python (com gRPC-Python e Flask para REST)
* **Comunicação**: gRPC (com Protocol Buffers) e RESTful API
* **Containerização**: Docker
* **Orquestração**: Kubernetes (Minikube)

## 🚀 Como Executar o Projeto

Siga os passos abaixo para configurar e executar toda a aplicação em sua máquina local.

### 1. Pré-requisitos

O ambiente foi projetado para sistemas Linux (baseados em Debian/Ubuntu). O script de instalação cuidará das seguintes dependências:
* Docker
* kubectl
* Minikube
* Node.js e npm

### 2. Passos para a Execução

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

* Após o script `run.sh` ser executado com sucesso, o **frontend estará acessível** no seu navegador em:
    > **http://localhost:3000**

* O **API Gateway**, que expõe os endpoints dos microsserviços, estará disponível no IP do Minikube. O script irá imprimir a URL no final, algo como:
    > **http://192.168.49.2** (o IP pode variar)

### 4. Parando e Limpando o Ambiente

Para parar a aplicação e remover todos os componentes criados (containers, deployments, etc.), basta pressionar `Ctrl+C` no terminal onde o `run.sh` está sendo executado.

O script irá capturar o sinal e executar uma rotina de limpeza automática, parando o Minikube e deletando todos os recursos do Kubernetes.

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
│   └── rest
├── proto
│   ├── download.proto
│   └── playlist.proto
├── README.md
├── run-k8s.sh
└── services
    ├── grpc
    │   ├── download (Python)
    │   └── playlist (Ruby)
    └── rest
        ├── download (Python)
        └── playlist (Ruby)
```

</details>