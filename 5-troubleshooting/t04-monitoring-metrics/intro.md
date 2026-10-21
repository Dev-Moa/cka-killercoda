# Monitoring Metrics

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

The Metrics Server is installed in `kube-system` for this exercise. It
may need a minute before `kubectl top` returns numbers. Nothing is
broken.

You read node metrics, create a deployment named `load` in the
`default` namespace, and read its pod metrics. CHECK passes when
`kubectl top node` and `kubectl top pod` both return rows and the
`load` deployment is Running.
