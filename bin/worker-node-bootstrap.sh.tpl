#!/bin/bash

exec > /var/log/worker-node-bootstrap.log 2>&1
set -x

# Debug: Confirm bootstrap run
echo "Bootstrap starting at $(date)"

# Inject internal SSH public key
mkdir -p /home/ubuntu/.ssh
echo "${internal_ssh_public_key}" >> /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/authorized_keys

# Update packages and install necessary tools
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gpg containerd

# Disable swap (required for Kubernetes)
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Enable IP forwarding (required for Kubernetes networking)
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Create keyrings directory for apt
sudo mkdir -p /etc/apt/keyrings

# Add Kubernetes GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg

# Add Kubernetes apt repository
echo "deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update and install Kubernetes components
sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Enable and start kubelet service
sudo systemctl enable --now kubelet

# Add kubectl alias for root user
echo "alias k=kubectl" >> /etc/bash.bashrc
echo "alias k=kubectl" >> /home/ubuntu/.bashrc

# Note: The join command is manual - copy /join-command.txt from control plane via SSH, then run: sudo $(cat /join-command.txt) --ignore-preflight-errors=NumCPU --ignore-preflight-errors=Mem