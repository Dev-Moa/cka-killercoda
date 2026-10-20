#!/bin/bash
# Step 1: the manifest exists in the kubelet's static pod directory and
# the static pod is Running.
test -f /etc/kubernetes/manifests/static-web.yaml || {
  echo "manifest /etc/kubernetes/manifests/static-web.yaml missing"
  exit 1
}
kubectl get pods | grep -q "static-web-.*Running" || {
  echo "no Running static-web pod found"
  exit 1
}
echo "Static pod static-web is Running"
