#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes

# The exercise runs etcdctl on controlplane (snapshot save/status/
# restore). Install it if the image does not ship it, version matched
# to the running etcd container.
if ! command -v etcdctl >/dev/null 2>&1; then
  img=$(kubectl get pod -n kube-system -l component=etcd \
    -o jsonpath='{.items[0].spec.containers[0].image}' 2>/dev/null)
  ver=$(echo "$img" | cut -d@ -f1 | sed -n 's#.*etcd:##p' | sed 's/^v//; s/-[0-9]*$//')
  case "$ver" in
    3.[0-9]*) : ;;
    *) ver=3.5.15 ;;
  esac
  if curl -fsSL "https://github.com/etcd-io/etcd/releases/download/v${ver}/etcd-v${ver}-linux-amd64.tar.gz" | tar xz -C /tmp; then
    mv "/tmp/etcd-v${ver}-linux-amd64/etcdctl" /usr/local/bin/etcdctl
  fi
  rm -rf "/tmp/etcd-v${ver}-linux-amd64"
fi
