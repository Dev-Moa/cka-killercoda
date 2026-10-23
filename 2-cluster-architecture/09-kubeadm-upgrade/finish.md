## What tripped me up

> After upgrading kubelet, it didn't start. I ran `systemctl restart kubelet` but forgot `systemctl daemon-reload` first. The systemd unit file changed but systemd didn't know about it. Always `daemon-reload` then `restart`. In that order. I lost 4 minutes on this during practice.
>
> On the worker node, I ran `kubeadm upgrade apply` instead of `kubeadm upgrade node`. Apply is for the control plane only. On workers it's `kubeadm upgrade node`. The error message is confusing — it doesn't immediately say "wrong command." It tries to run and fails partway through.
>
> Also: drain the worker BEFORE upgrading it. I upgraded first, then drained, and some pods got killed mid-upgrade when the node restarted. The safe order is: drain → upgrade → restart kubelet → uncordon.

<details>
<summary>Solution</summary>

```bash
# === CONTROL PLANE NODE ===

# Check current version. The image starts at v1.36.x, so the next minor
# is v1.37 - the target must be NEWER than what k get nodes shows.
k get nodes
kubeadm version

# Point the apt repo at v1.37 and look up the exact package strings
sudo sed -i -E 's|stable:/v[0-9.]+|stable:/v1.37|' /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
apt-cache madison kubeadm kubelet kubectl   # copy the exact 1.37.x strings

# Update kubeadm (use the exact string madison printed, not a guess)
sudo apt-mark unhold kubeadm
sudo apt-get install -y kubeadm=1.37.0-1.1
sudo apt-mark hold kubeadm

# Plan
sudo kubeadm upgrade plan

# Apply (version from the plan output)
sudo kubeadm upgrade apply v1.37.0
# If it stops on CoreDNS preflight errors, rerun with
#   --ignore-preflight-errors=CoreDNSUnsupportedPlugins,CoreDNSMigration

# Update kubelet + kubectl (exact strings from madison)
sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y kubelet=1.37.0-1.1 kubectl=1.37.0-1.1
sudo apt-mark hold kubelet kubectl

# Restart kubelet (daemon-reload BEFORE restart)
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Verify control plane
k get nodes

# === WORKER NODE (run from control plane, then SSH to worker) ===

# From control plane: drain worker
k drain node01 --ignore-daemonsets --delete-emptydir-data

# SSH to worker node
ssh node01

# Point the repo at v1.37 and update packages on the worker
sudo sed -i -E 's|stable:/v[0-9.]+|stable:/v1.37|' /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-mark unhold kubeadm kubelet kubectl
sudo apt-get install -y kubeadm=1.37.0-1.1 kubelet=1.37.0-1.1 kubectl=1.37.0-1.1
sudo apt-mark hold kubeadm kubelet kubectl

# Upgrade node config
sudo kubeadm upgrade node

# Restart kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Exit back to control plane
exit

# Uncordon worker
k uncordon node01

# Verify
k get nodes
```

> The image starts at v1.36.x, so the next minor is v1.37. `1.37.0-1.1`
> above is the example string — install whatever `apt-cache madison`
> actually prints for your repo.

Remember:
- Control plane: `kubeadm upgrade apply`
- Worker: `kubeadm upgrade node`
- Always drain workers before upgrading them
- Always uncordon after
- Check `k get nodes` first — the target must be a NEWER minor than the
  current version, never an older one
- Copy the exact package strings from
  `apt-cache madison kubeadm kubelet kubectl`, never guess them

</details>
