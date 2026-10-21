## What tripped me up

> **Bidirectional Rule Trap (Most Common Exam Failure):** Created perfect ingress rules on backend, but traffic was still blocked. Forgotten step: egress rules on the SOURCE pod (frontend). NetworkPolicy enforces BOTH ingress (destination) and egress (source). If frontend has default-deny egress without explicit allowlist, traffic never leaves. BOTH sides must say yes. Common test failure: "I wrote the policy correctly but traffic didn't flow."
>
> **DNS Discovery Broken by Network Policy:** All pods suddenly can't resolve service names (`nslookup kubernetes.default` times out). Usually because: I wrote app traffic rules but forgot explicit DNS egress. DNS runs on `kube-dns` service (usually IP 10.96.0.10) port UDP 53. Every namespace getting egress restriction needs an explicit "allow-dns-egress" rule. This breaks service discovery and confuses exam candidates.
>
> **Label Matching Case Sensitivity (Silent Failure):** Policy says `tier: backend` but pod is labeled `tier: Backend` (capital B). Label matching is CASE-SENSITIVE and fails silently with no error message. Traffic just blocks with no indication why. Fix: `kubectl get pods --show-labels` to verify exact label values, then compare with policy `.spec.podSelector.matchLabels`.
>
> **CNI Enforcement Doesn't Apply Universally:** NetworkPolicy objects exist on flannel clusters but traffic flows freely (flannel doesn't enforce). CKA exam uses Calico (which enforces), but self-testing might use non-enforcing CNI. Check: `k get pods -n kube-system | grep -i cni` shows which plugin. Calico, Cilium, Weave ENFORCE. Flannel, kubenet DO NOT. If policies don't work, check CNI first.
>
> **May 2026 Gotcha (Empty Selectors):** In k8s 1.35, an empty `podSelector: {}` in ingress means "all pods in this namespace" — it's a blanket allow. An empty `namespaceSelector: {}` means "all namespaces." Empty selectors are powerful but often misunderstood. Verify you're using them intentionally, not by accident.
>
> **Port Range Behavior (endPort Quirks):** Policy allows `port: 8080, endPort: 8090` (range). But on some CNIs (Calico specifically), `endPort` behavior changed between k8s 1.33 and 1.35. Test the upper bound: traffic on 8090 might be allowed or blocked depending on CNI version. Always test specific ports, not assume range behavior.
>
> **Traffic TIMEOUT vs REFUSED:** If traffic timeouts (hangs), policy is blocking it (good, working). If you get connection refused (RST packet), the pod isn't listening or there's another issue. Don't mistake connection refused for policy not working. Use `k exec <pod> -- netstat -tulnp` to verify target pod is actually listening on the port.

## Key Learning

- NetworkPolicies are pod label selectors, not namespace selectors alone
- Ingress rules applied to target pods
- Egress rules applied to source pods
- Must explicitly allow DNS egress or service discovery breaks
- Debugging: use `k describe pod` and check labels carefully
- Exam tests label matching precision

<details>
<summary>Solution</summary>

```bash
# Create namespaces
k create ns frontend backend database

# Label namespaces for cross-ns selection
k label ns frontend name=frontend
k label ns backend name=backend
k label ns database name=database

# Deploy frontend
k run frontend-web -n frontend --image=nginx:1.27 --labels=tier=frontend

# Deploy backend
k run backend-api -n backend --image=busybox:1.36 --command sleep 3600 --labels=tier=backend

# Deploy database
k run database-redis -n database --image=busybox:1.36 --command sleep 3600 --labels=tier=database

# Create services
k expose pod frontend-web -n frontend --port=80 --type=ClusterIP
k expose pod backend-api -n backend --port=8080 --type=ClusterIP
k expose pod database-redis -n database --port=6379 --type=ClusterIP

# Allow frontend → backend
cat <<EOF | k apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: backend
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: frontend
    ports:
    - protocol: TCP
      port: 8080
EOF

# Allow backend → database
cat <<EOF | k apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-database
  namespace: database
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: backend
    ports:
    - protocol: TCP
      port: 6379
EOF

# Allow DNS egress from all namespaces
for ns in frontend backend database; do
cat <<EOF | k apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: $ns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to: []
    ports:
    - protocol: UDP
      port: 53
EOF
done

# Test connectivity
# Frontend → Backend (should work)
k exec -it $(k get po -n frontend -o name | head -1) -n frontend -- curl -m 2 http://backend-api.backend.svc.cluster.local:8080

# Frontend → Database (should fail)
k exec -it $(k get po -n frontend -o name | head -1) -n frontend -- curl -m 2 http://database-redis.database.svc.cluster.local:6379
```

</details>
