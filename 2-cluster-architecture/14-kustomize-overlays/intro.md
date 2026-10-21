# Kustomize: Base and Overlay

You are root on controlplane of a two-node kubeadm cluster; kubectl is
ready and node01 is reachable with `ssh node01` if you ever need it.

This exercise builds a Kustomize base with a Deployment and a Service,
then applies a staging overlay that changes the namespace, the replica
count and adds a common label. All resources end up in the namespace
`exercise-14`.
