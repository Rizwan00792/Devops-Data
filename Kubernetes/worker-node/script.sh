#!/bin/bash

# Stop and disable firewalld
systemctl stop firewalld
systemctl disable firewalld

# Install yum-utils
yum install -y yum-utils

# Add Docker repository
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker packages
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Disable SELinux
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Add Kubernetes repository
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

# Remove containerd configuration
rm -rf /etc/containerd/config.toml

# Restart containerd
systemctl restart containerd

# Enable IP forwarding
echo "1" > /proc/sys/net/ipv4/ip_forward

# Load kernel modules
modprobe bridge
modprobe br_netfilter

# Install iproute-tc
yum install iproute-tc -y

# Install Kubernetes packages
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet
systemctl start kubelet
