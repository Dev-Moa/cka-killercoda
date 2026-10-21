# CNI install (Tigera Operator)

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

A CNI plugin gives pods their IPs and routes traffic between nodes.
The Tigera Operator installs Calico from one `Installation` resource;
the pod CIDR in that resource must equal the cluster's pod CIDR.

In this exercise you install the operator, create the `Installation`
with the right CIDR, and wait for the `calico-system` pods. Nothing is
pre-installed for this exercise.

Warning: this cluster already has a working CNI. Installing Calico on
top of it can break pod networking on the playground; that is part of
what the exercise shows, and a fresh scenario start restores it.
