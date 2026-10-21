# Exercise C05 — Kubeadm Install

Build a cluster from bare nodes: install the runtime and the kubeadm
packages, run `kubeadm init` on the control plane, join a worker, then
watch the nodes become Ready. Needs two clean Ubuntu nodes (a
Killercoda `ubuntu` scenario or two VMs) — not an existing cluster.

## Tasks

Steps 1–2 run on BOTH nodes, 3–4 on the control plane only, 5 on the
worker. Call the nodes `controlplane` and `node01`.

1. Install `containerd`, set its cgroup driver to `systemd` (the
   default config has it off — flip it, then restart containerd), and
   enable `net.ipv4.ip_forward`.
2. Add the Kubernetes apt repo (v1.31), install `kubelet kubeadm
   kubectl`, hold the three packages so apt never upgrades them, and
   start kubelet.
3. On the control plane: `kubeadm init` with
   `--apiserver-advertise-address <controlplane-ip>` and
   `--pod-network-cidr 10.244.0.0/16`. Copy `admin.conf` to
   `~/.kube/config`, apply the Flannel manifest. Save the printed
   `kubeadm join` line.
4. Verify the control plane node is Ready — it stays NotReady until
   the Flannel pods run.
5. On the worker: run the saved `kubeadm join`. Back on the control
   plane: both nodes Ready, and a test pod runs.

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- The kubelet uses the `systemd` cgroup driver (kubeadm v1.22+) and
  the runtime must match — that is the most common install failure.
- NotReady right after init is normal; the node flips Ready once the
  CNI pods are Running.
- Join token expired? On the control plane:
  `kubeadm token create --print-join-command` prints a fresh join line.
- `kubeadm init` a second time on the same node? `kubeadm reset -f`
  first.
- The docs pages are in the note's Docs section; Ctrl+F
  `apt-mark hold` (install), `pod-network-cidr` (init + join).

</details>

## Verify

```bash
kubectl get nodes                          # both nodes Ready, roles control-plane + <none>
kubectl get pods -n kube-flannel -o wide   # one Flannel pod per node
kubectl run web --image=nginx --restart=Never --port=80   # test pod
kubectl get pods -o wide                   # web Running on one of the nodes
```

When done, click **CHECK**.
