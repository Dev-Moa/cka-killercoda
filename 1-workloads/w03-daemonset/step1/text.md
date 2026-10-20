# DaemonSet on every node

A DaemonSet runs exactly one copy of a pod on every node, including
the control plane. This exercise tests the DaemonSet spec — it has no
`replicas` field, and the selector must match the template labels —
plus the toleration a pod needs to run on a tainted control plane
node.

This cluster is k3s: it has no `kube-proxy` DaemonSet.

1. List the DaemonSets that already exist in the cluster, in all
   namespaces, and note how many pods each runs.

2. Create a DaemonSet named `monitoring-daemon` in the `default`
   namespace with image `nginx` and pod label `app=monitoring-agent`.
   There is no `kubectl create daemonset` command: generate a
   Deployment skeleton with `--dry-run=client -o yaml`, change `kind`
   to `DaemonSet`, remove `replicas` and `strategy`, and make
   `selector.matchLabels` equal to the template labels.

3. Check how many pods it created and on which nodes. The control
   plane node is missing a pod — find out why (hint: describe the
   control plane node and look at its Taints).

4. Change the DaemonSet so its pods also run on the control plane
   node.

5. Verify there is exactly one `monitoring-daemon` pod on every node.

When done, click **CHECK**.
