# Exercise T02 — Control Plane and Worker Node Failure

Break the scheduler, the API server and a worker's kubelet, then fix
each one. Needs a kubeadm cluster where the control plane runs as
static pods and you can SSH to a worker. Do each break and fix one at
a time; a broken API server hides everything else.

## Part A — scheduler (kubeadm static pod)

Tasks:

1. The `test` pods stay Pending. Find which control plane component is
   unhealthy and why.
2. Fix it. The pods must schedule without you touching them.

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- Pending pods with no node and no events about resources means the
  scheduler. `kubectl get pods -n kube-system` shows it crashing.
  `kubectl logs kube-scheduler-<node> -n kube-system` and
  `kubectl describe pod` show the exec error. The fix is in
  `/etc/kubernetes/manifests/`. The kubelet restarts the pod on save.
- With the API server down, `kubectl` gives "connection refused". Use
  the container runtime: `crictl ps -a | grep apiserver` then
  `crictl logs <id>`, or the kubelet log `journalctl -u kubelet | grep
  apiserver`. Read the manifest for a wrong flag value.
- Node `NotReady` with condition `Unknown` and message "Kubelet stopped
  posting node status" means the node is not talking. On the host:
  `systemctl status kubelet`, `journalctl -u kubelet -xe`,
  `systemctl start kubelet`.

</details>

## Verify

```bash
kubectl get pods -n kube-system                   # scheduler and apiserver Running, RESTARTS stable
kubectl get pods -l app=test -o wide              # both Running on a node
kubectl get nodes                                 # all Ready
```

When done, click **CHECK**.
