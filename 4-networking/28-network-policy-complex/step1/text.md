# Exercise 28 — Complex NetworkPolicy (Multi-Namespace, Traffic Control)

Create multi-namespace NetworkPolicies with ingress/egress rules with careful label matching and debugging. Understand that NetworkPolicy enforcement depends on the CNI (Container Network Interface) plugin your cluster uses — not all CNIs enforce all policy rules equally.

## Conventions

NetworkPolicy troubleshooting involves multiple trap levels:

- **Primary Trap:** Ingress rules on destination pod but egress missing on source pod — traffic blocked at source
- **Secondary Trap (Gotcha 1):** Label selector typo or case mismatch — policies silently don't apply
- **Secondary Trap (Gotcha 2):** CNI doesn't support NetworkPolicy enforcement (e.g., flannel) — policies exist but don't block
- **Validation Criteria:** Your implementation is correct if:
  - Allowed traffic flows with exact port match
  - Disallowed traffic times out (not rejected, but blocked passively)
  - DNS works (explicit egress UDP 53 rule required)
  - `kubectl describe networkpolicy` shows correct selector labels
  - `k get pods --show-labels` confirms pod labels match policy selectors
- **Scoring:** Full credit for end-to-end connectivity working + all 3 namespaces isolated correctly. Partial for policies created but not tested.

## Important: CNI-Aware Testing

NetworkPolicy resources exist across all Kubernetes clusters, but whether they're *enforced* depends on your CNI:

- **Enforcing CNIs**: Calico, Cilium, Weave, Kube-router
- **Non-enforcing CNIs**: flannel, kubenet (pass-through)

If your CNI doesn't enforce policies, the NetworkPolicy objects exist but traffic flows freely. Exam clusters use enforcing CNIs (usually Calico). For testing locally, verify your CNI supports NetworkPolicy before debugging.

## Tasks

1. Create 3 namespaces: `frontend`, `backend`, `database`
2. Deploy apps:
   - Frontend (nginx): labels `tier=frontend`
   - Backend (busybox): labels `tier=backend`
   - Database (redis): labels `tier=database`
3. Create NetworkPolicies:
   - Allow frontend → backend (only port 8080)
   - Allow backend → database (only port 6379)
   - Deny all other traffic initially (prefer-deny ingress)
   - Allow DNS egress (UDP 53) to kube-dns for all pods
4. **Explicitly test connectivity** to confirm policies are enforced:
   - Frontend CAN reach backend on 8080 only
   - Frontend CANNOT reach database
   - Backend CAN reach database on 6379
   - Backend CANNOT reach frontend
5. Verify DNS still works from all namespaces (tests egress rules)
6. If policies don't enforce, verify CNI supports NetworkPolicy

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- **Check CNI enforcement first:** `k get pods -n kube-system | grep -i cni` or `kubectl describe node` to see CNI plugin
- For cross-namespace policies: use `namespaceSelector` with namespace labels (label namespaces first!)
- DNS rule: egress with `to: []` and `ports: [{protocol: UDP, port: 53}]` (empty `to` means all destinations)
- Test connectivity with **explicit port**: `k exec <pod> -- curl http://service.namespace.svc.cluster.local:8080`
- Debug: `k describe networkpolicy <name>` shows selectors AND rules clearly
- **Order matters:** ingress applied to destination pod, egress to source pod. Both must allow for traffic to flow.
- **Timeouts mean denial:** If `curl` hangs with no response, the policy is likely dropping packets (good sign policies work!)
- **CNI not enforcing?** Policies may exist but not be enforced. Verify with `k get networkpolicies` and check node's CNI plugin.

</details>

## Verify

```bash
# Pods are running in correct namespaces
k get pods -A

# NetworkPolicies exist
k get networkpolicies -A

# From frontend, test connectivity
k exec -it <frontend-pod> -n frontend -- curl http://backend.<backend>.svc.cluster.local:8080
# Should succeed

# From frontend, try database (should fail)
k exec -it <frontend-pod> -n frontend -- curl http://database.<database>.svc.cluster.local:6379
# Should timeout/fail

# Test DNS works
k exec -it <any-pod> -- nslookup kubernetes.default
# Should succeed
```

When done, click **CHECK**.
