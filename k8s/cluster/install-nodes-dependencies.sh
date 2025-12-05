# 1. Desativar swap

sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 2. Habilitar módulos kernel necessários para Kubernetes
 
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf 
    overlay 
    br_netfilter 
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# 3. Configurar parâmetros de rede do kernel

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-iptables = 1
    net.bridge.bridge-nf-call-ip6tables = 1
    net.ipv4.ip_forward = 1
EOF
 
sudo sysctl --system


# # 4. Instalar o Container Runtime (Containerd - Recomendado)
# # (Os comandos podem variar ligeiramente dependendo da sua distribuição, ex: Ubuntu/Debian)
# # Adicione repositórios do Docker/Containerd e instale.

# # 5. Instalar Kubeadm, Kubelet e Kubectl
# # (Use a versão 1.34.2, se possível, para manter a consistência do seu cluster atual)
# # Adicione o repositório do Kubernetes. Exemplo para Debian/Ubuntu:

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
