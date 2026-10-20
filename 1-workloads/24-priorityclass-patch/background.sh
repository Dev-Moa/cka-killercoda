#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes

# pre-create namespace exercise-24; everything else is the candidate's work
kubectl create namespace exercise-24 --dry-run=client -o yaml | kubectl apply -f -
exit 0
