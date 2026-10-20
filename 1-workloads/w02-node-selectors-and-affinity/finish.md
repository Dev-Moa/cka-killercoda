# Node selectors and affinity - done

The exam facts from this exercise:

- `nodeSelector` is one label with one value. In a pod it sits under
  `spec`; in a Deployment, under `spec.template.spec`.
- Node affinity adds operators: `In` (one of these values), `NotIn`
  (none of these), `Exists` (label present, any value).
- `requiredDuringSchedulingIgnoredDuringExecution` keeps the pod
  Pending when no node matches; `preferred...` only tries, then
  places the pod anywhere. `IgnoredDuringExecution` means a label
  change later does not move a running pod.
- Do not type the affinity block: copy it from the docs page "Assign
  Pods to Nodes using Node Affinity", then change key, operator, and
  values.
- The control plane node has the label
  `node-role.kubernetes.io/control-plane` with an empty value — match
  it with the `Exists` operator.
- Pods only land on the control plane node if they tolerate its taint
  `node-role.kubernetes.io/control-plane:NoSchedule`.
- Core commands: `kubectl label nodes <node> key=value`,
  `kubectl get nodes --show-labels`, `kubectl get pods -o wide`,
  `kubectl create deployment blue --image=nginx --replicas=3`,
  `kubectl edit deployment blue`.

The exercise is based on the node selector and node affinity notes in
`notes/2-Scheduling/23, 24` and exercise w02 in
`cka-prep/exercises/1-workloads/`.
