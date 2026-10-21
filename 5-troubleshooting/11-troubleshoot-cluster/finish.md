## What tripped me up

> **Kubelet Trap:** My first instinct when a node is NotReady was to run `kubectl describe node` from the control plane. That gives you conditions but not the root cause. The real answer is almost always in `journalctl -u kubelet` on the broken node itself. SSH first, check kubelet logs, then work backwards. I wasted 7 minutes on practice exam questions by troubleshooting from the wrong machine.
>
> **Kubelet Gotcha (Red Herring):** In k8s 1.35, the systemd service is `kubelet`, but the process might have a different PID if running in a container. Don't assume `ps aux | grep kubelet` shows the main process. Always use `systemctl status kubelet` for authoritative state.
>
> **CoreDNS Trap:** `nslookup` failing doesn't always mean CoreDNS is broken. Check `resolv.conf` inside the pod first — I had a case where the pod's DNS config was pointing to the wrong IP because of a network policy blocking UDP 53 to the kube-dns service. The CoreDNS pods were fine; the traffic just couldn't reach them. Verify: `k exec <pod> -- cat /etc/resolv.conf`
>
> **CoreDNS Gotcha (May 2026):** In k8s 1.35+, CoreDNS respects search domain order. If your test pod gets DNS timeout, check the search domains in `resolv.conf` — they're often set by the kubelet's `--cluster-domain` flag. A misconfigured search domain can cause subtle timeouts (too many attempted SRV records).
>
> **kube-proxy Trap:** Not all nodes have kube-proxy running. In some environments (e.g., kind, GKE with eBPF mode), kube-proxy may not exist. Check the actual cluster setup before assuming kube-proxy absence = failure. Always verify: `k get ds -n kube-system | grep proxy` or `k get pods -n kube-system -l k8s-app=kube-proxy`.
>
> **Audit Logs Gotcha:** I initially searched `grep "error"` which gave me nothing useful. The audit log format is JSON — you need to grep for specific verb patterns like `grep "verb.*delete"` or look for status codes. Also, not all clusters enable audit logging, so check if the apiserver was even started with audit flags before spending time looking for logs that don't exist. **May 2026 update:** Use `jq` if available: `cat /var/log/audit/audit.log | jq 'select(.user.username=="admin")' | jq '.verb'`

<details>
<summary>Solution</summary>

### Scenario A: kubelet

```bash
# SSH to worker
ssh worker-1

# Stop kubelet
sudo systemctl stop kubelet

# From control plane (different terminal)
k get nodes
# worker-1 shows NotReady after ~40 seconds

# Back on worker — check why
sudo systemctl status kubelet
sudo journalctl -u kubelet --no-pager -l | tail -30

# Fix: restart kubelet
sudo systemctl start kubelet

# Back on control plane
k get nodes
# worker-1 should be Ready again
```

### Scenario B: CoreDNS

```bash
# Check CoreDNS pods
k get pods -n kube-system -l k8s-app=kube-dns

# Check logs
k logs -n kube-system -l k8s-app=kube-dns

# Check ConfigMap
k get configmap coredns -n kube-system -o yaml

# Check endpoints
k get endpoints kube-dns -n kube-system
# Should show IPs of CoreDNS pods

# Test DNS
k run test-dns --image=busybox:1.37 --rm -it -- nslookup kubernetes.default.svc.cluster.local
```

### Scenario C: kube-proxy

```bash
# Check DaemonSet
k get ds kube-proxy -n kube-system

# Check pods
k get pods -n kube-system -l k8s-app=kube-proxy -o wide

# Check logs
k logs -n kube-system -l k8s-app=kube-proxy | tail -20

# Check ConfigMap
k get configmap kube-proxy -n kube-system -o yaml

# On a node, check iptables
sudo iptables-save | grep -c KUBE
```

### Scenario D: API Server audit logs

```bash
# SSH to control plane node
ssh control-plane

# Check apiserver manifest for audit configuration
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep -i audit

# Find audit log file (look for --audit-log-path flag)
sudo cat /var/log/audit/audit.log | jq . | head -50

# Find failed authentication attempts
sudo cat /var/log/audit/audit.log | jq 'select(.user.username=="unknown" or .status.code>=400)' | head -20

# Find specific user actions (e.g., resource deletion)
sudo tail -100 /var/log/audit/audit.log | jq 'select(.verb=="delete")'

# Check request count by verb
sudo cat /var/log/audit/audit.log | jq -r '.verb' | sort | uniq -c | sort -rn

# Search for RBAC denials
sudo cat /var/log/audit/audit.log | jq 'select(.stage=="ResponseComplete" and .status.code>=400)'
```

</details>
