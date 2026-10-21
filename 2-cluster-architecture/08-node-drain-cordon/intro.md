# Node Drain and Cordon

You are root on controlplane of a two-node kubeadm cluster; kubectl is
ready and node01 is reachable with `ssh node01` if you ever need it.
You take the worker node out for maintenance: cordon it so no new pods
are scheduled on it, drain its pods, then uncordon it and scale the
deployment back up. All work happens in the default namespace.
