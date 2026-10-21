#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes

# The image ships no Metrics Server; the exercise needs one. Install the
# upstream release and allow the kubelets' self-signed certs.
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl -n kube-system patch deployment metrics-server --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
kubectl -n kube-system rollout status deployment/metrics-server --timeout=180s

# metrics need a scrape cycle before `kubectl top` returns rows
for i in $(seq 1 24); do
  [ -n "$(kubectl top nodes --no-headers 2>/dev/null)" ] && break
  sleep 5
done
kubectl top nodes
exit 0
