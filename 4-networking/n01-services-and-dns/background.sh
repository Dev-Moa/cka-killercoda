#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes
# nothing to pre-create; the candidate makes the namespace, pod and services
exit 0
