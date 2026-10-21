#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes
# Each step plants its own break in step<N>/background.sh when the step
# starts (Part A scheduler, Part B API server, Part C worker kubelet).
exit 0
