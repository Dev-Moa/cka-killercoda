# Node selectors and affinity

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

In this exercise you steer pods to specific nodes by label. First the
simple way: `nodeSelector` with one label and one value. Then the
richer way: node affinity with the `In` and `Exists` operators.

You label the worker node, place one pod and two Deployments on the
right nodes, and add the toleration the control plane node needs. All
work happens in the `default` namespace.
