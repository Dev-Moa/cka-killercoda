# Troubleshoot Cluster Components

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

Something in the cluster's DNS path is broken: pods cannot resolve
service names, even though the CoreDNS pods look healthy. Audit logging
is switched on for the API server, so the audit log has entries to
read. You stop and restart the worker's kubelet yourself in Scenario A.

Restore name resolution, keep every node Ready, and leave kube-proxy
running on every node. The test pods live in the `default` namespace;
the cluster components are in `kube-system`.
