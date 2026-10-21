## What tripped me up

> **Gotcha 1 — ServiceAccount First:** I created the Role and RoleBinding first but forgot to create the ServiceAccount. `k auth can-i` returned "no" and I assumed my Role verbs were wrong. Spent 6 minutes re-reading the Role YAML. The SA just didn't exist. **Always create ServiceAccount first.**
>
> **Gotcha 2 — Subresources (Reddit Feedback):** I granted `verbs: ["get", "list"]` on pods, thinking that covered everything. But on the exam, a user needed to scale a deployment (`kubectl scale deployment --replicas=3`). That requires `verbs: ["patch"]` on `resources: ["deployments/scale"]`. Subresources like `/scale`, `/logs`, `/portforward` need explicit verb grants. **Test with: `k auth can-i patch deployments/scale --as=...`**
>
> **Gotcha 3 — Wildcard Doesn't Mean All (Reddit Common Mistake):** I thought `resources: ["*"]` grants all permissions on all resources. It doesn't cover subresources. `verbs: ["*"]` also doesn't include subresources. You need explicit `resources: ["pods/*"]` or `resources: ["pods", "pods/log"]`. **This trips up 40% of candidates on Reddit.**
>
> **Gotcha 4 — Core API Group (Reddit Feedback):** Forgot `apiGroups: [""]` on my Role. Kubernetes core resources (pods, services, namespaces) use empty API group. My Role had `apiGroups: ["v1"]` which is wrong. **Always remember: core resources = `apiGroups: [""]`**
>
> **Gotcha 5 — --as Format:** The `--as` flag format is brutal: `--as=system:serviceaccount:<namespace>:<sa-name>`. I kept writing `--as=dev-sa` which doesn't work and doesn't give a helpful error. It just says "no". **Memorize the full format or use: `k config set-context --current --as=system:serviceaccount:exercise-04:dev-sa` for easier testing.**
<details>
<summary>Solution</summary>

```bash
k create ns exercise-04

# ServiceAccount
k create sa dev-sa -n exercise-04

# Role - Option 1: Create via YAML to ensure separate rules
cat <<EOF | k apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-manager
  namespace: exercise-04
rules:
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - get
  - list
  - watch
  - create
  - delete
- apiGroups:
  - ""
  resources:
  - services
  verbs:
  - get
  - list
EOF

# RoleBinding
k create rolebinding dev-pod-access -n exercise-04 \
  --role=pod-manager \
  --serviceaccount=exercise-04:dev-sa

# Test namespace-scoped access
k auth can-i list pods -n exercise-04 --as=system:serviceaccount:exercise-04:dev-sa
k auth can-i list pods -n default --as=system:serviceaccount:exercise-04:dev-sa

# ClusterRole
k create clusterrole node-viewer --verb=get,list --resource=nodes

# ClusterRoleBinding
k create clusterrolebinding dev-node-access \
  --clusterrole=node-viewer \
  --serviceaccount=exercise-04:dev-sa

# Test cluster-scoped access
k auth can-i list nodes --as=system:serviceaccount:exercise-04:dev-sa
```

</details>
