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

# Set custom hostname (dynamic based on index)
hostnamectl set-hostname worker${worker_index}

# Update packages and install necessary tools
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gpg containerd

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

# Install bash-completion for kubectl and k alias
apt-get install -y bash-completion

COMPLETION_LINE="source <(kubectl completion bash)"
PROFILE_FILE="/etc/bash.bashrc"

if ! grep -q "$COMPLETION_LINE" "$PROFILE_FILE"; then
    echo "$COMPLETION_LINE" >> "$PROFILE_FILE"
fi

ALIAS_LINE="alias k='kubectl'"
COMPDEF_LINE="complete -o default -F __start_kubectl k" 
if ! grep -q "$ALIAS_LINE" "$PROFILE_FILE"; then
    echo "$ALIAS_LINE" >> "$PROFILE_FILE"
    echo "$COMPDEF_LINE" >> "$PROFILE_FILE"
fi

# Note: The join command is manual - copy /join-command.txt from control plane via SSH, then run