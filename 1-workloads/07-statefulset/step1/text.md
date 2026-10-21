# Exercise 07 — StatefulSet Deployment

Deploy a stateful application using StatefulSet. This exercise teaches ordered pod initialization, persistent storage, and stable network identities—critical for databases and distributed systems on the CKA.

## Context

StatefulSets are for applications that need:
- Stable, predictable pod names (not randomly generated like Deployments)
- Ordered pod startup and shutdown
- Persistent storage per pod replica
- Stable network identities (DNS names with ordinal suffixes)

Unlike Deployments where pod identity doesn't matter, StatefulSets maintain identity across restarts. Example: a MySQL cluster needs predictable names like `mysql-0`, `mysql-1`, `mysql-2` that survive pod recreations.

## Tasks

Work in the `default` namespace.

1. Create a headless Service for the StatefulSet (required for DNS routing)
2. Create a StatefulSet with 3 replicas using the `nginx:1.28` image
3. Verify pods start in order (mysql-0 first, then mysql-1, then mysql-2)
4. Verify each pod has a persistent volume claim attached
5. Delete a pod and observe it respawn with the same name and storage
6. Scale the StatefulSet up and down using `kubectl scale`
7. Delete the StatefulSet and verify PVCs persist (data survives)

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- Headless Service: set `spec.clusterIP: None` in the Service definition
- StatefulSet pods get DNS names like `nginx-0.nginx.default.svc.cluster.local`
- Use `.spec.serviceName` to reference the headless Service
- `.spec.volumeClaimTemplates` automatically creates a PVC for each replica
- Pod ordinals matter: `mysql-0` runs before `mysql-1` (controlled by `podManagementPolicy: OrderedReady`)
- `k get pvc` will show each pod's persistent claim

</details>

## Verify

```bash
# Headless Service created
k get svc mysql

# StatefulSet created
k get statefulset

# All 3 pods are Running and in order
k get pods -l app=mysql -o wide

# Each pod has storage
k get pvc

# Persistent DNS names work
k run debug --image=busybox:1.37 --rm -it -- nslookup mysql-0.mysql.default.svc.cluster.local

# Pod names are stable after deletion
k delete pod mysql-1
sleep 5
k get pods
# mysql-1 is recreated with the same name
```

When done, click **CHECK**.
