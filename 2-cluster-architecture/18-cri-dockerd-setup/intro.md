# CRI-dockerd Setup

You are root on controlplane of a two-node kubeadm cluster; kubectl is
ready and node01 is reachable with `ssh node01` if you ever need it.

Kubernetes removed dockershim in v1.24, so a node that must keep using
Docker as its container runtime needs cri-dockerd. This exercise
installs and configures cri-dockerd on controlplane: kernel modules,
sysctl parameters, Docker, the cri-dockerd binary, systemd service and
socket units, and the CRI socket. Do all the work on controlplane
itself.
