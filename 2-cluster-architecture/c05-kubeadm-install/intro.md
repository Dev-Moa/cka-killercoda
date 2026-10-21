# Kubeadm Install

You are root on controlplane of a two-node kubeadm cluster; node01 is
reachable with `ssh node01` if you ever need it. This exercise rebuilds
the cluster from the node level: `kubeadm init` on the control plane,
Flannel as the pod network, and `kubeadm join` on the worker, until
both nodes are Ready and a test pod runs. The two nodes already have
kubeadm, kubelet, kubectl and containerd installed and an old cluster
running. Run `sudo kubeadm reset -f` on BOTH nodes first, then follow
the tasks.
