# Storage with WaitForFirstConsumer Binding

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

A StorageClass with `volumeBindingMode: WaitForFirstConsumer` delays
the PVC binding until a pod uses the PVC. The PVC stays Pending until
then, which is normal, not an error. This matters for `local` volumes
that live on one node: the pod must be scheduled onto that node.

In this exercise you create the StorageClass, a local PV, a PVC that
stays Pending, and then a pod that mounts the PVC and makes it Bound.

The directory `/tmp/k8s-pv` already exists on both nodes, so either
node name works in the PV node affinity. The `exercise-25` namespace
is already created for you.
