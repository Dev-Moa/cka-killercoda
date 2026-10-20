# Resource requests tuning

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

A Deployment named `web` already runs in namespace `exercise-23` with 3
replicas, but its resource requests are so large that no node can fit
them — every pod stays Pending. You will read the pod Events and the
node capacity to see the real numbers, then lower the requests so all 3
pods schedule and run.

You work in namespace `exercise-23`.
