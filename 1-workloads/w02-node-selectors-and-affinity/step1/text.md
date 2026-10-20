# Node selectors and affinity

Steer pods to specific nodes: first with `nodeSelector`, then with
node affinity.

1. Find the name of the worker node and list its labels:

   `kubectl get nodes --show-labels`{{exec}}

2. Label the worker node with `size=Large`:

   `kubectl label nodes <worker> size=Large`{{exec}}

3. Create a pod named `data-processor` with image `nginx` in the
   `default` namespace that must run on a node labeled `size=Large`,
   using `nodeSelector`. Verify it lands on the worker node.

4. Label the worker node with `color=blue`:

   `kubectl label nodes <worker> color=blue`{{exec}}

5. Create a Deployment named `blue` with image `nginx` and 3
   replicas. Check which nodes its pods can go to.

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

Fragments to reuse:

For pod `data-processor`, add under `spec` (same level as
`containers`):

```yaml
nodeSelector:
  size: Large
```{{copy}}

For Deployment `blue`, add under `spec.template.spec` (same level as
`containers`):

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: color
          operator: In
          values:
          - blue
```{{copy}}

For Deployment `red`, add under `spec.template.spec`:

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: node-role.kubernetes.io/control-plane
          operator: Exists
tolerations:
- key: node-role.kubernetes.io/control-plane
  operator: Exists
  effect: NoSchedule
```{{copy}}

When done, click **CHECK**.
