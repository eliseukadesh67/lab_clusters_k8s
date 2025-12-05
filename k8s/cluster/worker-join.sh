#!/bin/bash

# Define a função de uso para exibir como o script deve ser executado
usage() {
  echo "Uso: $0 <TOKEN_DO_KUBEADM>"
  echo "Exemplo: $0 abcdef.0123456789abcdef"
  exit 1
}

# 1. Verifica se o token (argumento $1) foi fornecido
if [ -z "$1" ]; then
  echo "🚨 ERRO: O token do Kubeadm é obrigatório."
  usage
fi

# Variáveis
TOKEN=$1
MASTER_ENDPOINT="master:6443"  # Use o nome DNS ou IP do seu Master
CA_HASH="sha256:<HASH_DO_SEU_CLUSTER>" # Substitua pelo hash real!
CRI_SOCKET="unix:///var/run/containerd/containerd.sock"

# ATENÇÃO:
# Você deve obter o CA_HASH real do seu Master após executar o 'kubeadm init'.
# Se não usar o hash real, o join falhará.
# O comando para obter o hash é: openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256

echo "---"
echo "✅ Iniciando a junção do Worker com token: $TOKEN"
echo "---"

# 2. Executa o comando de junção real
sudo kubeadm join "$MASTER_ENDPOINT" \
  --token "$TOKEN" \
  --discovery-token-ca-cert-hash "$CA_HASH" \
  --cri-socket "$CRI_SOCKET"

# 3. Verifica o status do comando join
if [ $? -eq 0 ]; then
  echo "---"
  echo "🎉 Sucesso! O Worker foi adicionado ao cluster. Verifique no Master."
  echo "---"
else
  echo "---"
  echo "❌ Falha ao tentar juntar o Worker ao cluster. Verifique a saída acima."
  echo "---"
  exit 1
fi