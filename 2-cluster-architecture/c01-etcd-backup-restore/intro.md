# etcd Backup and Restore

You are root on controlplane of a two-node kubeadm cluster; kubectl is
ready and node01 is reachable with `ssh node01` if you ever need it.

You will save a snapshot of etcd, change the cluster, and restore the
snapshot so the change disappears. Everything runs on controlplane; the
one deployment you create lives in the `default` namespace.
