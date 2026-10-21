# TLS Configuration Update

You are root on controlplane of a two-node kubeadm cluster; kubectl is
ready and node01 is reachable with `ssh node01` if you ever need it.

A TLS server runs in the `exercise-30` namespace, configured through a
ConfigMap that currently allows only TLS 1.3. You add TLS 1.2 support to
the ConfigMap and restart the workload so both protocol versions work.
