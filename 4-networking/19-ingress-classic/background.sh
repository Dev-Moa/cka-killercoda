#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes

# Install the ingress-nginx controller (bare-metal manifest, NodePort) so
# the IngressClass "nginx" exists and the Ingress gets an ADDRESS.
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0/deploy/static/provider/baremetal/deploy.yaml
# Publish the controlplane IP as the Ingress ADDRESS (a NodePort service
# has no load-balancer IP for the controller to report).
CP_IP=$(kubectl get node controlplane -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
kubectl -n ingress-nginx patch deployment ingress-nginx-controller --type=json \
  -p "[{\"op\":\"add\",\"path\":\"/spec/template/spec/containers/0/args/-\",\"value\":\"--publish-status-address=${CP_IP}\"}]"
kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=300s
kubectl get ingressclass
exit 0
