# kubeadm Upgrade

You are root on controlplane of a two-node kubeadm cluster; kubectl is
ready and node01 is reachable with `ssh node01`.

This exercise upgrades the cluster from its current minor version to the
next one. The control plane goes first with `kubeadm upgrade apply`;
the worker node follows with `kubeadm upgrade node` after a drain. The
upgrade is cluster-wide, so no namespace is involved.
