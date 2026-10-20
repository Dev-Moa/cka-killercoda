#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# simulate the real exam layout: taint the control plane so task 3 has
# a reason to discover (idempotent: only if missing)
CP=$(kubectl get nodes -l node-role.kubernetes.io/control-plane -o jsonpath='{.items[0].metadata.name}')
if [ -z "$CP" ]; then echo "no control plane node found"; exit 1; fi
kubectl describe node "$CP" | grep -q 'node-role.kubernetes.io/control-plane:NoSchedule' || kubectl taint nodes "$CP" node-role.kubernetes.io/control-plane:NoSchedule
exit 0
