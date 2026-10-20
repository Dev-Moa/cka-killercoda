# Pod Basics

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

A pod is the smallest unit in Kubernetes — it runs one or more
containers.

In this exercise you create one pod with resource requests, limits, and
labels, then add and remove labels on the running pod.

All work happens in the `exercise-01` namespace.
