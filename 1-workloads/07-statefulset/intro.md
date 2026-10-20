# StatefulSet

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

In this exercise you build a stateful application in the `default`
namespace: a headless Service `mysql` and a StatefulSet `mysql` with
3 replicas. Each pod gets a stable name like `mysql-0` and its own
persistent volume claim.

You will watch the pods start in order, delete one and see it come
back with the same name, then scale the StatefulSet up to 4 and down
to 2 replicas.
