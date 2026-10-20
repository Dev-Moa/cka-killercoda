# Multi-container Pod

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

A native sidecar is an init container with `restartPolicy: Always`.
It starts before the main container and keeps running next to it.

In this exercise you create a pod named `logger` in the namespace
`exercise-02`. A main container writes a log line every 3 seconds, and
the sidecar tails the same log file through a shared `emptyDir` volume.
