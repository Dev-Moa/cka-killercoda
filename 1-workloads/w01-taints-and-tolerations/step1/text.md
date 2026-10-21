# Exercise W01 — Taints and Tolerations
Taint a node so it repels pods, then let one pod in with a toleration.
This tests that you know which side the taint goes on (the node) and
which side the toleration goes on (the pod), and that you can remove a
taint.

## Tasks

Pick one worker node. Call it `<worker>` below.

1. Check whether `<worker>` has any taints.
2. Taint `<worker>` with key `spray`, value `mortein`, effect
   `NoSchedule`.
3. Create a pod named `mosquito` with image `nginx`. Check its status
   and explain to yourself why it is in that state.
4. Create a pod named `bee` with image `nginx` that tolerates the taint
   from task 2. Verify it runs on `<worker>`.
5. Check the taints on the control plane node.
6. Remove the `NoSchedule` taint from the control plane node. Watch what
   happens to `mosquito` and note which node it lands on.
7. Put the control plane taint back.

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- `kubectl taint nodes --help` shows the `key=value:effect` form. A
  trailing `-` on the taint removes it.
- A toleration is a pod setting: it sits at the same level as
  `containers`, not inside it. Generate the pod YAML with
  `--dry-run=client -o yaml`, then add it.
- `kubectl describe node <node> | grep Taint` shows a node's taints.
- The control plane taint is
  `node-role.kubernetes.io/control-plane:NoSchedule`.

</details>

## Verify

```bash
kubectl describe node <worker> | grep Taint      # after task 2: spray=mortein:NoSchedule
kubectl get pods                                  # after task 3: mosquito Pending
kubectl get pods -o wide                          # after task 4: bee Running on <worker>
kubectl get pods -o wide                          # after task 6: mosquito Running on the control plane node
```

When done, click **CHECK**.
