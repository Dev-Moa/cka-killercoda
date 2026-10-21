#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes

# Build the stack the exercise grades: a namespace, a ConfigMap holding
# an nginx TLS config that allows only TLS 1.3, a self-signed cert
# Secret, a Deployment mounting both, and a ClusterIP Service.
kubectl create namespace exercise-30

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/tls-server.key -out /tmp/tls-server.crt \
  -subj "/CN=tls-server.exercise-30.svc" >/dev/null 2>&1
kubectl -n exercise-30 create secret tls tls-server-certs \
  --cert=/tmp/tls-server.crt --key=/tmp/tls-server.key
rm -f /tmp/tls-server.key /tmp/tls-server.crt

kubectl apply -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: tls-server-config
  namespace: exercise-30
data:
  nginx.conf: |
    server {
        listen 443 ssl;
        ssl_certificate     /etc/tls/tls.crt;
        ssl_certificate_key /etc/tls/tls.key;
        ssl_protocols       TLSv1.3;
        location / {
            return 200 'ok';
        }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tls-server
  namespace: exercise-30
spec:
  replicas: 1
  selector:
    matchLabels:
      app: tls-server
  template:
    metadata:
      labels:
        app: tls-server
    spec:
      containers:
      - name: nginx
        image: nginx:1.27-alpine
        ports:
        - containerPort: 443
        volumeMounts:
        - name: tls-config
          mountPath: /etc/nginx/conf.d
          readOnly: true
        - name: tls-certs
          mountPath: /etc/tls
          readOnly: true
      volumes:
      - name: tls-config
        configMap:
          name: tls-server-config
      - name: tls-certs
        secret:
          secretName: tls-server-certs
---
apiVersion: v1
kind: Service
metadata:
  name: tls-server
  namespace: exercise-30
spec:
  selector:
    app: tls-server
  ports:
  - port: 443
    targetPort: 443
EOF

kubectl -n exercise-30 rollout status deployment/tls-server --timeout=180s
