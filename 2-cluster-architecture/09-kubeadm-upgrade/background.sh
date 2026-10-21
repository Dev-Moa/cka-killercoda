#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes

# Record the pre-upgrade kubelet version straight from the node object.
# The checker compares it with the node version at CHECK time to prove
# an upgrade happened, without hinting at any target version.
mkdir -p /tmp/exam
kubectl get node controlplane -o jsonpath='{.status.nodeInfo.kubeletVersion}' \
  > /tmp/exam/initial-version.txt
