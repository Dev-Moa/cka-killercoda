# PriorityClass

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

A PriorityClass is a cluster-wide object that gives pods a priority
number. Higher number means higher priority. When a node is full, a
high-priority pod can evict lower-priority pods to make room
(preemption) — but only if its policy allows it.

In this exercise you will create two PriorityClasses (`high-priority`
and `low-priority`) and run one pod in each class. You work in the
`default` namespace.
