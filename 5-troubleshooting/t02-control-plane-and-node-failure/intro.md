# Control Plane and Worker Node Failure

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

Three failures arrive one at a time, one per step: a control plane
component that stops scheduling, an API server that stops answering,
and a worker node that goes NotReady. Each step plants its own break
when you enter it, so finish a step before you click Next.

Fix each one in `/etc/kubernetes/manifests/` or on the node, and leave
the cluster with every component Running and both nodes Ready. The
test deployment lives in the `default` namespace.
