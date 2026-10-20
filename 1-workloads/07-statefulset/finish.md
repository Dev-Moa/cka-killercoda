# StatefulSet - done

The exam facts from this exercise:

- A StatefulSet needs a **headless Service** (`clusterIP: None`). Without
  it the pods lose their DNS names and you cannot reach `mysql-0` by name.
- Pod names are stable and ordered: `mysql-0` starts before `mysql-1`
  before `mysql-2`. Deleting `mysql-1` brings back a pod with the same
  name and the same storage.
- Scale-down removes pods in reverse order (highest ordinal first);
  scale-up follows the order.
- `volumeClaimTemplates` creates one PVC per pod automatically, named
  `data-mysql-<ordinal>` — one `1Gi` claim each here.
- Deleting the StatefulSet does **not** delete the PVCs. A new
  StatefulSet with the same names binds to the old volumes and the data
  survives.
- Core commands: `kubectl get statefulset`, `kubectl get pvc`,
  `kubectl delete pod mysql-1`, `kubectl scale statefulset mysql
  --replicas=2`.

The exercise is based on exercise 07 in `cka-prep/exercises/1-workloads/`.
