# KubeConfig

You are root on controlplane of a two-node kubeadm cluster; kubectl is
ready and node01 is reachable with `ssh node01` if you ever need it.

The exercise drills the kubeconfig file: copy the admin config, use it
with `--kubeconfig`, set the default namespace of its context to
kube-system, break and fix its server port, and make it the default
file for your shell.
