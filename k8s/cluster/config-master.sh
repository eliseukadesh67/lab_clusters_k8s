#!/bin/bash

# Inicialização do cluster

sudo kubeadm init --config=master-config.yaml

# Acesso a config do kubeadm

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Aplicar o manifesto do Calico (exemplo para versões recentes)
# # Você deve escolher uma CNI que corresponda à faixa de IP (Pod CIDR) que você usou,
# # mas se não especificou, a faixa padrão do Calico funciona bem.
#

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
