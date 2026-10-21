# Commands & Arguments

You are root on controlplane of a two-node kubeadm cluster; kubectl is
ready and node01 is reachable with `ssh node01` if you ever need it.

A pod definition can change what a container runs without rebuilding
the image: `command` replaces the image's ENTRYPOINT and `args`
replaces its CMD. This exercise drills the exam's favourite one-liner:
a busybox pod that sleeps.
