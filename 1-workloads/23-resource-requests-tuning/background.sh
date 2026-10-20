#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# pre-create namespace exercise-23 and Deployment web (3 replicas) with impossible requests (100Gi memory, 100 cpu) so every pod stays Pending
kubectl create namespace exercise-23 --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: exercise-23
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:1.27
        resources:
          requests:
            memory: 100Gi
            cpu: 100
EOF
exit 0
