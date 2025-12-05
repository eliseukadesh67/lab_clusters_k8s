#!/bin/bash

# Cores para o output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Verificando dependências necessárias...${NC}"

# Função para instalar pacotes no Debian/Ubuntu
install_packages() {
    echo "Atualizando a lista de pacotes..."
    sudo apt-get update
    echo "Instalando pacotes necessários: $@"
    sudo apt-get install -y "$@"
}

# 1. Verificar e instalar o Docker
if ! command -v docker &> /dev/null; then
    echo "Docker não encontrado. Instalando Docker..."
    install_packages ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker $USER
    echo -e "${GREEN}Docker instalado com sucesso! Por favor, faça logout e login novamente para aplicar as permissões do grupo Docker.${NC}"
else
    echo -e "${GREEN}Docker já está instalado.${NC}"
fi

# 2. Verificar e instalar o kubectl
if ! command -v kubectl &> /dev/null; then
    echo "kubectl não encontrado. Instalando kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    echo -e "${GREEN}kubectl instalado com sucesso.${NC}"
else
    echo -e "${GREEN}kubectl já está instalado.${NC}"
fi

# 3. Verificar e instalar o Minikube
if ! command -v minikube &> /dev/null; then
    echo "Minikube não encontrado. Instalando Minikube..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
    echo -e "${GREEN}Minikube instalado com sucesso.${NC}"
else
    echo -e "${GREEN}Minikube já está instalado.${NC}"
fi

if ! command -v node &> /dev/null; then
    echo "Node.js não encontrado. Instalando a versão LTS..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
    echo -e "${GREEN}Node.js e npm instalados com sucesso.${NC}"
else
    echo -e "${GREEN}Node.js e npm já estão instalados.${NC}"
fi

# 5. Verificar e instalar o Helm
if ! command -v helm &> /dev/null; then
    echo "Helm não encontrado. Instalando Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo -e "${GREEN}Helm instalado com sucesso.${NC}"
else
    echo -e "${GREEN}Helm já está instalado.${NC}"
fi

echo -e "\n${GREEN}Verificação de dependências concluída!${NC}"