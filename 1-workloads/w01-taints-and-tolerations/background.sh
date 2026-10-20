#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes

# simulate the real exam layout: taint the control plane so pods need a toleration to land there (idempotent: only if missing)
CP=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -m1 controlplane)
if [ -z "$CP" ]; then echo "no control plane node found"; exit 1; fi
kubectl describe node "$CP" | grep -q 'node-role.kubernetes.io/control-plane:NoSchedule' || kubectl taint nodes "$CP" node-role.kubernetes.io/control-plane:NoSchedule
exit 0
