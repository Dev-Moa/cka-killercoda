<details>
<summary>Solution</summary>

```bash
# on both nodes: containerd with systemd cgroup + ip_forward
sudo apt update && sudo apt install -y containerd
sudo containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
cat <<'EOF' | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

# on both nodes: the apt repo, the three packages, hold them
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet

# control plane only: init + kubeconfig + CNI
sudo kubeadm init --apiserver-advertise-address <controlplane-ip> --pod-network-cidr 10.244.0.0/16
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
wget https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubectl apply -f kube-flannel.yml
kubectl get nodes                          # controlplane Ready

# worker only: the join line that init printed
sudo kubeadm join <controlplane-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>

# back on the control plane
kubectl get nodes                          # two Ready nodes
kubectl run web --image=nginx --restart=Never --port=80
```

**Key insight:** the order is runtime → packages (held) → init →
kubeconfig → CNI → join. The two traps that cost time are the cgroup
driver mismatch and the node sitting NotReady until the CNI runs.

</details>
