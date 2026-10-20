# PriorityClass patch

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

A PriorityClass gives pods a priority number: a higher value means
the pod is scheduled first. In this exercise you create a
PriorityClass, create a Deployment without it, then use
`kubectl patch` to add the priority class to the pod template. You
also create a second Deployment with no priority to compare.

You work in namespace `exercise-24`; it is already created.
