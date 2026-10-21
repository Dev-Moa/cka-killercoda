#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes

# Record the etcd client URLs so the checker can compare against them.
mkdir -p /tmp/exam
grep -o -- '--listen-client-urls=[^ ]*' /etc/kubernetes/manifests/etcd.yaml | cut -d= -f2 > /tmp/exam/etcd-client-urls.txt

# The break (applied LAST, no waiting): the API server points at an etcd
# that does not exist - wrong IP, right port. The kubelet restarts the
# static pod and it crash-loops with "dial tcp 10.0.0.5:2379".
sed -i 's|--etcd-servers=https://127.0.0.1:2379|--etcd-servers=https://10.0.0.5:2379|' /etc/kubernetes/manifests/kube-apiserver.yaml
exit 0
