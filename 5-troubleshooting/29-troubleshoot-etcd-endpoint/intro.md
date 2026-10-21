# Troubleshoot Broken Cluster (Incorrect etcd Endpoint)

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

The control plane is broken: `kubectl` does not answer, because the
API server cannot reach etcd. The fault is in a static pod manifest on
controlplane. No namespace is involved.

Find the wrong value, fix it in `/etc/kubernetes/manifests/`, and wait
for the kubelet to restart the API server. CHECK passes when the API
server is Running and `kubectl get nodes` works again.
