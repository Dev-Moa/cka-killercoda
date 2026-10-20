#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes

# CK-X q11 setup: nothing to pre-create; the cluster starts clean.
exit 0
