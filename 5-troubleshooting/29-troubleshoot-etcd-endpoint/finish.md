## What tripped me up

> **Static Pod Trap:** I found the wrong IP in kube-apiserver but didn't think to verify the CORRECT IP by checking etcd.yaml. Edited to what I thought was right and it was still wrong. **Always verify from source.** The correct etcd endpoint is the source of truth — never guess.
>
> **Static Pod Gotcha:** I tried to `kubectl apply` the manifest — that doesn't work for static pods. Must edit in place in `/etc/kubernetes/manifests/`. The kubelet watches that directory and auto-restarts pods when files change. **May 2026 update:** kubelet file watching can have race conditions on very fast SSDs. If the pod doesn't restart within 10 seconds, try: `sudo systemctl restart kubelet` (on the control plane node only).
>
> **Certificate Gotcha (v1.35):** In k8s 1.35, etcd certificate validation is stricter. If switching etcd endpoints, verify both use the same certificate scheme (self-signed vs CA-signed). A mismatch causes `x509: certificate signed by unknown authority` errors. Check: `grep "client-cert-auth" /etc/kubernetes/manifests/etcd.yaml` must match the connection string security flags.
>
> **Port Gotcha:** etcd default is `2379` (client port), not `2384` (peer port). Common mistake: `--etcd-servers=https://127.0.0.1:2384` (peer port) instead of `2379`. Always verify in the etcd manifest: `grep "listen-client-urls" /etc/kubernetes/manifests/etcd.yaml`.
>
> **Hostname vs IP Trap:** Some clusters use etcd hostnames (e.g., `etcd-0`) instead of IPs. If the manifest says `--etcd-servers=https://etcd-0:2379` but the error says "name resolution failed", this is actually correct — DNS isn't working because the API server pod is broken. Don't try to change hostname to IP (that breaks HA clusters). Instead, fix the connection string format.

## Key Learning

- Static pods in `/etc/kubernetes/manifests/` auto-restart on file changes
- API server cannot start without etcd connection
- etcd endpoint must be exact: `https://127.0.0.1:2379` or `https://<etcd-ip>:2379`
- Troubleshooting: check pod logs first, then manifest
- Exam tests understanding of control plane components

<details>
<summary>Solution</summary>

```bash
# 1. Check if API server is running (it may be stuck/restarting)
k get pod -n kube-system -l component=kube-apiserver

# 2. If accessible, check logs
k logs -n kube-system kube-apiserver-<node> --tail=50
# Look for error like: "dial tcp 10.0.0.5:2379: connection refused"

# 3. SSH into control plane node
ssh <control-plane-ip>

# 4. Check current etcd endpoint in API server manifest
grep "etcd-servers" /etc/kubernetes/manifests/kube-apiserver.yaml
# Example: --etcd-servers=https://10.0.0.5:2379

# 5. Get CORRECT endpoint from etcd manifest
grep "listen-client-urls" /etc/kubernetes/manifests/etcd.yaml
# Example: --listen-client-urls=https://127.0.0.1:2379,https://10.0.0.10:2379

# 6. The correct endpoint should be one from etcd's listen URLs
# Usually: https://127.0.0.1:2379 (if etcd on same node)
# Or: https://<etcd-ip>:2379 (if separate etcd node)

# 7. Edit and fix
sudo sed -i 's|--etcd-servers=https://10.0.0.5:2379|--etcd-servers=https://127.0.0.1:2379|' /etc/kubernetes/manifests/kube-apiserver.yaml

# Or manually edit
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
# Find and correct the etcd-servers line

# 8. Save (vi: Esc, :wq)
# kubelet will auto-detect change and restart pod

# 9. Verify API server comes up (may take 10-15 seconds)
k get pod -n kube-system kube-apiserver-<node-name>
# STATUS should change from CrashLoopBackOff to Running

# 10. Test cluster is working
k get nodes
k version
```

</details>
