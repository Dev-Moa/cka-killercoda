# DaemonSet - done

The exam facts from this exercise:

- There is no `kubectl create daemonset`. Generate a Deployment with
  `--dry-run=client -o yaml`, change `kind` to `DaemonSet`, and remove
  `replicas` and `strategy`.
- A DaemonSet is a ReplicaSet with the count "one per node", so there
  is no `replicas` field.
- `selector.matchLabels` must equal the labels in `template.metadata`.
- Taints apply to DaemonSet pods like to any pod. The control plane has
  the taint `node-role.kubernetes.io/control-plane:NoSchedule`.
- To reach the control plane, add a toleration under `template.spec`
  with that key, `operator: Exists`, and `effect: NoSchedule`.
- `kubectl describe node <controlplane> | grep Taint` shows the taint;
  `kubectl get ds -A` and `kubectl get pods -l app=monitoring-agent -o
  wide` verify the result.

The exercise is based on the DaemonSet and taints notes in
`notes/2-Scheduling/` (26, 22) and exercise W03 in
`cka-prep/exercises/1-workloads/`.
