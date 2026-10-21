#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes
# pre-create the exercise-25 namespace for the candidate
kubectl create namespace exercise-25 --dry-run=client -o yaml | kubectl apply -f -
# a local PV needs its path to exist on the node it is pinned to;
# the task gives /tmp/k8s-pv, so create it on both nodes
mkdir -p /tmp/k8s-pv
ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=10 node01 'mkdir -p /tmp/k8s-pv' 2>/dev/null || true
exit 0
