# Pod Security Standards

You are root on controlplane of a two-node kubeadm cluster; kubectl is
ready and node01 is reachable with `ssh node01` if you ever need it.

Pod Security Standards enforce security rules at the namespace level
through labels. This exercise builds three namespaces — `exercise-20`,
`exercise-20-baseline` and `exercise-20-audit` — each enforcing a
different PSS level or mode.
