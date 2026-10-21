# kubectl debug: Pod and Node

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

`kubectl debug` adds a temporary container to a running pod, or
starts a privileged pod on a node with the host filesystem mounted at
`/host`. Nothing is broken here: the exercise drills the two commands
and their traps.

You work in the `exercise-17` namespace. The CHECK looks for the pod,
its ephemeral debug container, and the node debug pod.
