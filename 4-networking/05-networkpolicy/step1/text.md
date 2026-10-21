# Exercise 05 — NetworkPolicy

Create NetworkPolicies to control pod-to-pod traffic. Watch out for the DNS gotcha.

## Tasks

1. Create a namespace called `exercise-05`
2. Deploy two pods:
   - `frontend` with image `nginx:1.27` and label `role=frontend`
   - `backend` with image `nginx:1.27` and label `role=backend`
3. Verify that `frontend` can reach `backend` on port 80 (should work before any policy)
4. Create a NetworkPolicy named `backend-policy` that:
   - Applies to pods with label `role=backend`
   - Allows ingress only from pods with label `role=frontend` on port 80
   - Allows egress to DNS (UDP port 53) — if you skip this, DNS breaks
5. Verify that `frontend` can still reach `backend`
6. Create a third pod `attacker` with label `role=attacker` and verify it cannot reach `backend`

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- Once you apply any NetworkPolicy to a pod, all traffic not explicitly allowed is denied
- You almost always need to allow DNS egress (UDP port 53), or the pod can't resolve service names
- Test connectivity with `k exec <pod> -- curl -m2 http://<target-ip>`

</details>

## Verify

```bash
# Get backend IP
BACKEND_IP=$(k get pod backend -n exercise-05 -o jsonpath='{.status.podIP}')

# Frontend -> Backend: should work
k exec frontend -n exercise-05 -- curl -m2 http://$BACKEND_IP

# Attacker -> Backend: should time out
k exec attacker -n exercise-05 -- curl -m2 http://$BACKEND_IP
```

When done, click **CHECK**.
