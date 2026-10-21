# Exercise W03 — DaemonSet on Every Node

Run one copy of a pod on every node, including the control plane. This
tests the DaemonSet spec (no `replicas`, selector must match the
template labels) and the toleration a pod needs to land on a tainted
control plane node.

## Tasks

1. List the DaemonSets that already exist in the cluster, in all
   namespaces. Note which one runs kube-proxy and how many pods it has.
2. Create a DaemonSet named `monitoring-daemon` in the `default`
   namespace with image `nginx` and pod label `app=monitoring-agent`.
3. Check how many pods it created and on which nodes. If the control
   plane node is missing, find out why.
4. Change the DaemonSet so its pods also run on the control plane node.
5. Verify there is exactly one `monitoring-daemon` pod on every node.

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- There is no `kubectl create daemonset`. Copy the spec from the docs
  page "DaemonSet", section "Writing a DaemonSet Spec", or generate a
  Deployment with `--dry-run=client -o yaml`, change `kind` to
  `DaemonSet`, and delete the `replicas` line.
- `selector.matchLabels` must equal the labels in `template.metadata`.
- `kubectl describe node <controlplane> | grep Taint` shows why the pod
  is missing there. The pod needs a toleration for that taint, under
  `template.spec`.
- `kubectl get ds -A` lists DaemonSets. The DESIRED column is the node
  count that qualifies.

</details>

## Verify

```bash
kubectl get ds -A                                 # kube-proxy, DESIRED = node count
kubectl get ds monitoring-daemon                  # after task 2: DESIRED = worker count only
kubectl get pods -l app=monitoring-agent -o wide  # after task 4: one pod per node, control plane included
```

When done, click **CHECK**.
