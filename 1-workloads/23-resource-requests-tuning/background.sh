#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes

# pre-create namespace exercise-23; the Deployment is the candidate's work
# (task 2 has them create it with requests that are too high on purpose)
kubectl create namespace exercise-23 --dry-run=client -o yaml | kubectl apply -f -
exit 0
