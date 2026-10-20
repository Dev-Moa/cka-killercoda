# Taints & Tolerations

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

A taint on a node stops pods that do not tolerate it from scheduling
there. A toleration on a pod lets it land on a tainted node.

In this exercise you will taint the worker node, run one pod that stays
Pending and one that tolerates the taint, then remove and restore the
control plane taint. All pods go in the `default` namespace.
