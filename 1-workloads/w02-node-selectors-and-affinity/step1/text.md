# Node selectors and affinity

Steer pods to nodes by label. First the simple way (`nodeSelector`,
one label, one value), then the richer way (node affinity with `In`,
`NotIn`, `Exists`). Both are pod settings, so in a Deployment they go
under `template.spec`.

Steer pods to specific nodes: first with `nodeSelector`, then with
node affinity.

1. Find the name of the worker node and list its labels.

2. Label the worker node with `size=Large`.

3. Create a pod named `data-processor` with image `nginx` in the
   `default` namespace that must run on a node labeled `size=Large`,
   using `nodeSelector`. Verify it lands on the worker node.

4. Label the worker node with `color=blue`.

5. Create a Deployment named `blue` with image `nginx` and 3 replicas.
   Check which nodes its pods can go to.

6. Edit Deployment `blue` so its pods run only on nodes where the
   label `color` is `blue`, using node affinity with the `In`
   operator. Verify all 3 pods are on the worker node.

7. Create a Deployment named `red` with image `nginx` and 2 replicas
   that runs only on the control plane node, using node affinity with
   the `Exists` operator. Check the nodes' actual labels first
   (`kubectl get nodes --show-labels`) and match the role label that
   marks the control plane node. The control plane node is tainted
   with `node-role.kubernetes.io/control-plane:NoSchedule`, so add a
   toleration for that taint next to the affinity. Verify both pods
   are on the control plane node.

When done, click **CHECK**.
