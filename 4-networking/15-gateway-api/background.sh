#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes

# Install the Gateway API standard CRDs (v1.2.1) and the NGINX Gateway
# Fabric controller (v1.6.2) so a GatewayClass named "nginx" exists and
# a Gateway can reach Programmed: True (tasks 2 and 7 need a controller).
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
kubectl apply -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v1.6.2/deploy/crds.yaml
kubectl apply -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v1.6.2/deploy/default/deploy.yaml
kubectl -n nginx-gateway rollout status deployment/nginx-gateway --timeout=300s
kubectl get gatewayclass
exit 0
