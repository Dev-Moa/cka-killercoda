# Exercise 11 — Troubleshoot Cluster Components

Fix a broken cluster. This exercise simulates common failures you'll see on the CKA: kubelet down, kube-proxy misconfigured, CoreDNS not resolving.

## Conventions

Before working through these scenarios, understand the trap architecture:

- **Primary Trap:** A legitimate cluster misconfiguration that breaks functionality (e.g., kubelet service stopped)
- **Secondary Trap (Gotcha):** A realistic red herring that makes diagnosis harder (e.g., checking wrong `kubeconfig` context, nodes showing status from wrong cluster)
- **Validation Criteria:** Your answer is correct if:
  - The cluster component is running and healthy
  - All nodes return to `Ready` or services return to running state
  - Subsequent `kubectl` commands work without errors
  - You've identified the root cause, not just the symptom

**Scoring:** Full credit for fixing the issue + explaining the root cause. Partial credit for fixing without explanation.

## Tasks

### Scenario A: Broken kubelet

1. SSH to a worker node
2. Stop the kubelet service
3. From the control plane, observe the node status change to `NotReady`
4. SSH back to the worker and check kubelet logs
5. Restart kubelet and verify the node comes back to `Ready`

### Scenario B: CoreDNS troubleshooting

1. Create a pod and try to resolve a service name — should fail if CoreDNS is broken
2. Check CoreDNS pods in `kube-system`
3. Check CoreDNS logs for errors
4. Verify the CoreDNS ConfigMap for misconfigurations
5. Check that the `kube-dns` service has endpoints
6. Fix any issues and verify DNS resolution works

### Scenario C: kube-proxy

1. Check if kube-proxy pods are running on all nodes
2. Check kube-proxy logs
3. Verify kube-proxy ConfigMap
4. Check iptables rules on a node

### Scenario D: API Server audit logs (Kubernetes 1.35 troubleshooting)

1. Find where audit logs are stored on the control plane node
2. Check the audit policy configuration in the apiserver manifest
3. Look for failed authentication attempts in the audit log
4. Find requests that were denied by RBAC
5. Correlate user identity to request details

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- `systemctl status kubelet` and `journalctl -u kubelet` for kubelet issues
- CoreDNS pods run as a Deployment in `kube-system`
- `k exec <pod> -- nslookup kubernetes` to test DNS
- kube-proxy runs as a DaemonSet in `kube-system`
- `iptables-save | grep <service-name>` to check kube-proxy rules
- Audit logs typically at `/var/log/audit/audit.log` or `/var/log/kubernetes/audit/audit.log`
- Check `/etc/kubernetes/manifests/kube-apiserver.yaml` for `--audit-log-path` and `--audit-policy-file`
- Look for `"verb":"delete"` or `"user":{"username":"system:admin"}` in audit logs to find specific operations

</details>

## Verify

```bash
# All nodes Ready
k get nodes

# DNS works
k run test-dns --image=busybox:1.36 --rm -it -- nslookup kubernetes

# Services are routable
k get endpoints -n kube-system
```

When done, click **CHECK**.
