# Taints & Tolerations - done

The exam facts from this exercise:

- The taint goes on the **node**; the toleration goes on the **pod**,
  under `spec` at the same level as `containers` — never inside it.
- Add a taint: `kubectl taint nodes <node> spray=mortein:NoSchedule`.
- Remove a taint with a trailing `-`:
  `kubectl taint nodes <node> key=value:effect-`.
- Generate the pod YAML with
  `kubectl run bee --image nginx --dry-run=client -o yaml`, then edit —
  never hand-write the manifest from scratch.
- Show taints with `kubectl describe node <node> | grep Taint`.
- A taint does not send a pod to a node; it only lets the node refuse
  pods that do not tolerate it.
- `NoSchedule` blocks new pods, `NoExecute` also evicts running ones,
  `PreferNoSchedule` is only a preference — putting the control plane
  taint back does not evict `mosquito`.

The exercise is based on the taints and tolerations note in
`notes/2-Scheduling/22` and exercise w01 in
`cka-prep/exercises/1-workloads/`.
