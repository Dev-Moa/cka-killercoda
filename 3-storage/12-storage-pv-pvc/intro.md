# Storage: PV, PVC, and StorageClass

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

A PersistentVolume (PV) is a piece of storage in the cluster. A
PersistentVolumeClaim (PVC) is a request for storage that binds to a
matching PV. A pod mounts the PVC, not the PV.

In this exercise you create a hostPath PV with the `manual` storage
class, bind a PVC to it, mount it in a pod, write a file, recreate the
pod and see the file survive. In the second step you delete the PVC and
check what the `Retain` reclaim policy does to the PV.

There is no dynamic provisioner and no default StorageClass on this
cluster, so the PV must be created by hand. The `exercise-12` namespace
is already created for you.
