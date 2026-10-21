#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes

# --- Scenario D needs audit logging, which the kubeadm image does not
# enable. Add an audit policy and the audit flags/mounts to the API
# server static pod (idempotent), then wait for the API server to return.
MANIFEST=/etc/kubernetes/manifests/kube-apiserver.yaml
if ! grep -q -- '--audit-log-path' "$MANIFEST"; then
  mkdir -p /var/log/kubernetes/audit
  cat > /etc/kubernetes/audit-policy.yaml <<'EOF'
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
EOF
  cp "$MANIFEST" /tmp/kube-apiserver.yaml.pre-audit
  # flags: right after the "- kube-apiserver" command entry
  sed -i '/^    - kube-apiserver$/a\    - --audit-policy-file=/etc/kubernetes/audit-policy.yaml\n    - --audit-log-path=/var/log/kubernetes/audit/audit.log\n    - --audit-log-maxage=7\n    - --audit-log-maxbackup=2\n    - --audit-log-maxsize=50' "$MANIFEST"
  # mounts: right after "volumeMounts:"
  sed -i '/^    volumeMounts:$/a\    - mountPath: /etc/kubernetes/audit-policy.yaml\n      name: audit-policy\n      readOnly: true\n    - mountPath: /var/log/kubernetes/audit\n      name: audit-log' "$MANIFEST"
  # volumes: right after "  volumes:"
  sed -i '/^  volumes:$/a\  - hostPath:\n      path: /etc/kubernetes/audit-policy.yaml\n      type: File\n    name: audit-policy\n  - hostPath:\n      path: /var/log/kubernetes/audit\n      type: DirectoryOrCreate\n    name: audit-log' "$MANIFEST"
fi

# wait for the API server to come back after the manifest change
for i in $(seq 1 60); do
  kubectl --request-timeout=5s get --raw /healthz >/dev/null 2>&1 && break
  sleep 5
done

# give the audit log something to find: a failed authentication (401),
# RBAC denials (403) and a delete
curl -sk -o /dev/null -H "Authorization: Bearer this-token-is-bogus" https://127.0.0.1:6443/api/v1/namespaces
curl -sk -o /dev/null -H "Authorization: Bearer this-token-is-bogus" https://127.0.0.1:6443/api/v1/secrets
kubectl --request-timeout=10s --as=system:serviceaccount:default:intruder get secrets -A >/dev/null 2>&1
kubectl --request-timeout=10s --as=system:serviceaccount:default:intruder delete pods -n kube-system --all >/dev/null 2>&1
kubectl --request-timeout=10s create configmap audit-probe --from-literal=a=b >/dev/null 2>&1
kubectl --request-timeout=10s delete configmap audit-probe >/dev/null 2>&1

# --- Scenario B break: cluster DNS stops answering. CoreDNS pods, logs
# and Corefile stay healthy; the kube-dns Service selector no longer
# matches the CoreDNS pods, so the Service has no endpoints.
kubectl --request-timeout=10s -n kube-system patch svc kube-dns -p '{"spec":{"selector":{"k8s-app":"kube-dnss"}}}'
exit 0
