#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes

# Task 1 asks the candidate to inspect the CRDs already in the cluster.
# A fresh kubeadm cluster has none, so seed one unrelated example CRD.
# It must not give away the CronTab CRD the candidate builds in task 2.
kubectl apply -f - <<'EOF'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: virtualservers.networking.example.com
spec:
  group: networking.example.com
  versions:
    - name: v1beta1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                port:
                  type: integer
  scope: Cluster
  names:
    plural: virtualservers
    singular: virtualserver
    kind: VirtualServer
    shortNames:
    - vs
EOF
