# ConfigMap & Secret

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

ConfigMaps hold non-secret config data and Secrets hold credentials.
A pod can load both as environment variables, and it can mount a
ConfigMap as files in a directory.

In this exercise you will create a ConfigMap, a Secret, and a pod that
loads all keys as env vars and mounts the ConfigMap at `/etc/config/`.
You work in the `exercise-03` namespace.
