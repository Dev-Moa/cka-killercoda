## What tripped me up

> I installed cri-dockerd but didn't enable IP forwarding. Node stayed NotReady because networking wasn't configured. Then I forgot to load `overlay` and `br_netfilter` modules — pods wouldn't start. Always do the full network setup BEFORE starting the service. Once cri-dockerd is running, kubelet needs a full restart (`systemctl restart kubelet`) to recognize it, not just a reload.

<details>
<summary>Solution</summary>

```bash
# SSH into worker node
ssh <node-ip>

# 1. Download cri-dockerd (example version)
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.14/cri-dockerd_0.3.14.3-0~ubuntu-focal_amd64.deb

# 2. Install
sudo dpkg -i cri-dockerd_0.3.14.3-0~ubuntu-focal_amd64.deb

# 3. Load required kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter

# 4. Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
# Persist across reboots
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sudo sysctl -p

# 5. Enable and start cri-dockerd
sudo systemctl enable cri-dockerd
sudo systemctl start cri-dockerd

# 6. Verify socket exists
sudo ls -la /run/cri-dockerd.sock

# 7. Check cri-dockerd is running
sudo systemctl status cri-dockerd

# 8. Update kubelet to use cri-dockerd
# Edit /etc/kubernetes/kubelet.conf or /etc/sysconfig/kubelet
sudo sed -i 's|--container-runtime=containerd|--container-runtime=remote|' /etc/kubernetes/kubelet.conf
sudo sed -i '/--container-runtime=remote/a --container-runtime-endpoint=unix:///run/cri-dockerd.sock' /etc/kubernetes/kubelet.conf

# 9. Restart kubelet (full restart, not reload)
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# 10. Check node status (may take 30 seconds)
k get nodes
# Should show Ready status
```

Reference: https://kubernetes.io/docs/setup/production-environment/container-runtimes/

</details>
