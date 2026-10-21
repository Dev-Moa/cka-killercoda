#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes

# Install Helm on controlplane (this exercise is all Helm).
curl -fsSL https://get.helm.sh/helm-v3.17.1-linux-amd64.tar.gz | tar xz
mv linux-amd64/helm /usr/local/bin/helm
helm version --short
