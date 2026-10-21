# Exercise 29 — Troubleshoot Broken Cluster (Incorrect etcd Endpoint)

Debug and fix a broken control plane where API server points to wrong etcd endpoint. Tests troubleshooting methodology and static pod modification.

## Conventions

Trap architecture for this exercise:

- **Primary Trap:** API server misconfigured to point to wrong etcd endpoint (wrong IP, wrong port, or wrong protocol)
- **Secondary Trap (Gotcha):** Static pod not restarting due to kubelet watching race condition, or multiple etcd instances running (one broken one working)
- **Validation Criteria:** Your answer is correct if:
  - API server pod transitions from `CrashLoopBackOff` to `Running` within 30 seconds
  - `k get nodes` and `k get pods -A` execute successfully
  - etcd connection string matches `/etc/kubernetes/manifests/etcd.yaml` exactly
- **Scoring:** Full credit for fix + explanation of root cause. Partial for fix alone.

## Tasks

1. Cluster is broken: API server won't start
2. Check kube-apiserver pod logs
3. Find the error: incorrect etcd endpoint IP or port
4. SSH into control plane node
5. Edit `/etc/kubernetes/manifests/kube-apiserver.yaml`
6. Correct the etcd endpoint in `--etcd-servers=` flag
7. Verify IP/port matches `/etc/kubernetes/manifests/etcd.yaml`
8. Save and wait for API server to restart
9. Verify cluster is healthy:
   - `k get nodes` works
   - `k get pods -A` works
   - API server is Running

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- Check kube-apiserver logs: `k logs -n kube-system kube-apiserver-<node>` (if APIserver partially runs)
- If logs unavailable, SSH to node and check: `journalctl -u kubelet -f`
- Get correct etcd endpoint: `grep "\-\-listen-client-urls" /etc/kubernetes/manifests/etcd.yaml`
- Edit manifest: `sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml`
- Look for line: `--etcd-servers=https://...`
- After fix, wait 10-15 seconds for pod to restart

</details>

## Verify

```bash
# Check no errors in logs
k logs -n kube-system kube-apiserver-<node-name> | tail -20

# API server is Running
k get pod -n kube-system kube-apiserver-<node-name>

# Basic cluster operations work
k get nodes
k get pods -A
k api-resources
```

When done, click **CHECK**.
