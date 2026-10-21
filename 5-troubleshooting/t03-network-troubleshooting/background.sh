#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes

# The exercise's own Setup block, run hidden (the candidate must not see
# the breaks). No node names in it, so it runs as written.
kubectl create deployment hostnames --image=registry.k8s.io/serve_hostname --replicas=3
kubectl expose deployment hostnames --port=80 --target-port=9377          # break 1: app listens on 9376
kubectl scale deployment coredns -n kube-system --replicas=0              # break 2: no DNS
exit 0
