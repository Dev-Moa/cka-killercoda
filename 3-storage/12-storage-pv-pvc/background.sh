#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes
# pre-create the exercise-12 namespace for the candidate
kubectl create namespace exercise-12 --dry-run=client -o yaml | kubectl apply -f -
exit 0
