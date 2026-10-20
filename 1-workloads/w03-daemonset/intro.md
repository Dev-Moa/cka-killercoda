# DaemonSet

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it. You work in the
`default` namespace.

A DaemonSet runs exactly one pod on every node. The control plane node
carries the taint `node-role.kubernetes.io/control-plane:NoSchedule`,
so a DaemonSet pod lands there only when its pod template tolerates
that taint.

In this exercise you will create a DaemonSet, see why its pod is
missing on the control plane, and fix it with a toleration.
