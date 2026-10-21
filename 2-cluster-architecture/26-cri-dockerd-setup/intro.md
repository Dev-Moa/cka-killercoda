# CRI-dockerd Setup

You are root on controlplane of a two-node kubeadm cluster; kubectl is
ready and node01 is reachable with `ssh node01`. This exercise installs
cri-dockerd on node01 — the adapter that lets kubelet keep using Docker
as the container runtime. Do the whole exercise on node01: install the
package, load the kernel modules, enable IP forwarding, point kubelet at
the cri-dockerd socket, and leave node01 Ready.
