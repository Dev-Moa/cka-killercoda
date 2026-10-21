# Exercise W02 — Node Selectors and Node Affinity
Steer pods to nodes by label. First the simple way (`nodeSelector`,
one label, one value), then the richer way (node affinity with
`In`, `NotIn`, `Exists`). Both are pod settings, so in a Deployment
they go under `template.spec`.

## Tasks

Work in the `default` namespace.

Pick one worker node. Call it `<worker>` below.

1. List the labels on `<worker>`.
2. Label `<worker>` with `size=Large`.
3. Create a pod named `data-processor` with image `nginx` that must run
   on a node labeled `size=Large`, using `nodeSelector`. Verify it lands
   on `<worker>`.
4. Label the same `<worker>` node with `color=blue`. Both labels stay on
   this one worker node — the control plane node gets no labels in this
   exercise.
5. Create a deployment named `blue` with image `nginx` and 3 replicas.
   Its pods must carry the label `app=blue` (`kubectl create deployment
   blue --image=nginx` sets it automatically). Check which nodes its
   pods can go to (think about taints).
6. Edit the deployment `blue` so its pods run only on nodes where the
   label `color` is `blue`, using node affinity. Verify all 3 pods are
   on `<worker>`.
7. Create a deployment named `red` with image `nginx` and 2 replicas
   that runs only on the control plane node: node affinity with the
   `Exists` operator on the label
   `node-role.kubernetes.io/control-plane`, and its pods must carry the
   label `app=red`. The control plane node is tainted
   (`node-role.kubernetes.io/control-plane:NoSchedule`), so the pods
   also need a toleration for that taint or they stay Pending. Verify.

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- `kubectl label nodes <node> key=value` adds a label;
  `kubectl get node <node> --show-labels` lists them.
- `nodeSelector` sits under `spec` at the same level as `containers`.
  In a Deployment that is `spec.template.spec`.
- The affinity block is long. Do not type it. Open the docs page
  "Assign Pods to Nodes using Node Affinity" and copy the
  `requiredDuringSchedulingIgnoredDuringExecution` example, then change
  key, operator and values.
- The control plane node carries the label
  `node-role.kubernetes.io/control-plane` with an empty value, so
  `Exists` is the operator to match it. Task 7 only works if the
  control plane taint lets the pods in. Check with
  `kubectl describe node | grep Taint` and handle it.

</details>

## Verify

```bash
kubectl get node <worker> --show-labels            # size=Large, color=blue
kubectl get pod data-processor -o wide            # NODE = <worker>
kubectl get pods -l app=blue -o wide              # all 3 on <worker>
kubectl get pods -l app=red -o wide               # both on the control plane node
```

When done, click **CHECK**.
