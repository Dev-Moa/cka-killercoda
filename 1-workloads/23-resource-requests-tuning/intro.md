# Resource requests tuning

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

A resource request is the amount of CPU and memory the scheduler must
find free on a node before it places a pod there. If the request is
bigger than any node can give, the pod stays Pending forever.

In this exercise you create a Deployment whose requests are too high
on purpose, read the pod Events and the node capacity to see the real
numbers, then lower the requests so all 3 pods schedule and run.

You work in namespace `exercise-23`; it is already created.
