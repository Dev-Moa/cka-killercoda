#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes
# nothing to pre-create; the candidate creates the argocd namespace,
# installs Argo CD and writes the Application
exit 0
