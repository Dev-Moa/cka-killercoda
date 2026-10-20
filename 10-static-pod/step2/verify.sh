#!/bin/bash
# Step 2: the manifest is gone and the kubelet removed the static pod.
test ! -f /etc/kubernetes/manifests/static-web.yaml || {
  echo "manifest /etc/kubernetes/manifests/static-web.yaml still present"
  exit 1
}
if kubectl get pods | grep -q "static-web-"; then
  echo "static-web pod still exists"
  exit 1
fi
echo "Static pod removed"
