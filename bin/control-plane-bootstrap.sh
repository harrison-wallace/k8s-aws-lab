#!/bin/bash

exec > /var/log/control-plane-bootstrap.log 2>&1
set -x

# Inject internal SSH private key for connecting to workers
mkdir -p /home/ubuntu/.ssh
echo "${internal_ssh_private_key}" > /home/ubuntu/.ssh/id_ed25519
chown ubuntu:ubuntu /home/ubuntu/.ssh/id_ed25519
chmod 600 /home/ubuntu/.ssh/id_ed25519

# Update packages and install necessary tools
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl software-properties-common git gpg containerd

# Disable swap (required for Kubernetes)
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Enable IP forwarding (required for Kubernetes networking)
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Create keyrings directory for apt
mkdir -p /etc/apt/keyrings

# Add Kubernetes GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg

# Add Kubernetes apt repository
echo "deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

# Update and install Kubernetes components
apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Enable and start kubelet service
systemctl enable --now kubelet

# Initialize the Kubernetes control plane (use Calico's default CIDR to avoid mismatch)
kubeadm init --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors=NumCPU --ignore-preflight-errors=Mem

# Set up kubeconfig for the root user
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Also set up kubeconfig for the ubuntu user (to allow non-root kubectl access)
mkdir -p /home/ubuntu/.kube
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

# Add kubectl alias for root user
echo "alias k=kubectl" >> /etc/bash.bashrc
echo "alias k=kubectl" >> /home/ubuntu/.bashrc

# Install Calico network plugin (updated to latest compatible version)
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.0/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.0/manifests/custom-resources.yaml

# Generate and save the join command for worker nodes
kubeadm token create --print-join-command > /join-command.txt