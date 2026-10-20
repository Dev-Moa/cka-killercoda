# Deployment Rollout

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

A Deployment keeps a set of pod replicas running and rolls out image
changes one pod at a time. In this exercise you will create a
Deployment named `webapp` in the `exercise-06` namespace, update its
image in a rolling update, check the rollout history, and roll back to
the previous version.

The `exercise-06` namespace is already created for you.
