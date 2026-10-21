#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes

# Record the default kubeconfig current-context so the CHECK can prove
# the exercise left the original config untouched.
mkdir -p /tmp/exam
kubectl config current-context > /tmp/exam/original-context.txt
