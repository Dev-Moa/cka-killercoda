# Exercise 18 — CRI-dockerd Installation & Configuration

Install and configure cri-dockerd as a container runtime for a Kubernetes node. This is common when upgrading clusters that need Docker support or when preparing a mixed-runtime cluster.

## Context

Kubernetes deprecated dockershim in v1.20 and removed it in v1.24. To continue using Docker as a container runtime, you must install CRI-dockerd explicitly. The exam may ask you to prepare a node to join a cluster using Docker via CRI-dockerd, or troubleshoot why a node can't join because the runtime isn't configured.

## Tasks

1. Load the required kernel modules: `overlay` and `br_netfilter`
2. Configure kernel networking parameters via sysctl
3. Install Docker (required dependency for CRI-dockerd)
4. Download and install CRI-dockerd binary from GitHub releases
5. Create systemd service files for cri-docker.service and cri-docker.socket
6. Enable and start the cri-docker services
7. Verify the CRI-dockerd socket is listening at `/run/cri-dockerd.sock`

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- Download the latest amd64 release from https://github.com/Mirantis/cri-dockerd/releases
- Use `curl -s https://api.github.com/repos/Mirantis/cri-dockerd/releases/latest` to get the latest version automatically
- The socket path must match what you pass to kubelet: `--cri-socket=unix:///run/cri-dockerd.sock`
- Kernel modules persist only if added to `/etc/modules-load.d/`
- Sysctl configuration in `/etc/sysctl.d/` survives reboots
- Check service status with: `sudo systemctl status cri-docker.service`
- Verify socket exists: `ls -la /run/cri-dockerd.sock`
- Check logs if service fails: `sudo journalctl -u cri-docker.service -n 50`

</details>

## Verify

```bash
# Check kernel modules are loaded
lsmod | grep overlay
lsmod | grep br_netfilter

# Check sysctl parameters are set
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.ipv4.ip_forward

# Check CRI-dockerd is running
sudo systemctl status cri-docker.service
sudo systemctl status cri-docker.socket

# Verify the socket exists and is listening
ls -la /run/cri-dockerd.sock

# Test CRI socket connectivity
sudo crictl version
```

When done, click **CHECK**.
