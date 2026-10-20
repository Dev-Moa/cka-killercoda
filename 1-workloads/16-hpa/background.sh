#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes
# pre-creates the exercise-16 namespace
kubectl create namespace exercise-16 --dry-run=client -o yaml | kubectl apply -f -
exit 0
