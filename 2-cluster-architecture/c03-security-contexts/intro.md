# Security Contexts

You are root on controlplane of a two-node kubeadm cluster; kubectl is
ready and node01 is reachable with `ssh node01` if you ever need it.

A security context sets the user ID and Linux capabilities a container
runs with: set it at container level for one container, at pod level
for all of them. This exercise works in the `default` namespace.
