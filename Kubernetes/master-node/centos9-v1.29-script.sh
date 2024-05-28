
#!/bin/bash

# Stop and disable firewalld
sudo systemctl stop firewalld
sudo systemctl disable firewalld

# Install yum-utils
sudo yum install -y yum-utils

# Add Docker repository
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Disable SELinux
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Add Kubernetes repository
sudo tee /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

# Remove containerd config
sudo rm -rf /etc/containerd/config.toml

# Restart containerd
sudo systemctl restart containerd

# Enable IP forwarding
echo "1" > /proc/sys/net/ipv4/ip_forward

# Load kernel modules
sudo modprobe bridge
sudo modprobe br_netfilter

# Install iproute-tc
sudo yum install iproute-tc -y

# Install Kubernetes components
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

# Initialize Kubernetes cluster
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors=all

# Set up kubeconfig for current user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=/etc/kubernetes/admin.conf

# Deploy Calico CNI
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/custom-resources.yaml
kubectl create deployment rc --image=nginx
