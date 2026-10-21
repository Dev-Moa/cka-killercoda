# Exercise 26 — CRI-dockerd Installation and Configuration

Install and configure cri-dockerd as a container runtime alternative to containerd. Essential for clusters using Docker as the container runtime.

## Tasks

1. SSH into a worker node
2. Install cri-dockerd using the `.deb` package:
   - Download from GitHub releases
   - Install the package
3. Configure system for cri-dockerd:
   - Enable IP forwarding using `sysctl`
   - Add required kernel modules (`overlay`, `br_netfilter`)
4. Enable and start cri-dockerd service:
   - `systemctl enable cri-dockerd`
   - `systemctl start cri-dockerd`
5. Verify cri-dockerd socket is available
6. Configure kubelet to use cri-dockerd
7. Restart kubelet and verify node is Ready

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- Download URL: `https://github.com/Mirantis/cri-dockerd/releases`
- Install: `sudo dpkg -i cri-dockerd_*_amd64.deb`
- Enable IP forwarding: `sudo sysctl -w net.ipv4.ip_forward=1`
- Load modules: `sudo modprobe overlay` and `sudo modprobe br_netfilter`
- Check socket: `ls -la /run/cri-dockerd.sock`
- Kubelet config: `--container-runtime=remote --container-runtime-endpoint=unix:///run/cri-dockerd.sock`

</details>

## Verify

```bash
# Socket exists and is accessible
sudo ls -la /run/cri-dockerd.sock

# Service is running
sudo systemctl status cri-dockerd

# Kernel modules loaded
lsmod | grep overlay
lsmod | grep br_netfilter

# IP forwarding enabled
cat /proc/sys/net/ipv4/ip_forward

# Kubelet configured to use it
grep container-runtime /etc/kubernetes/kubelet.conf

# Node is Ready
k get nodes
```

When done, click **CHECK**.
