# Network Troubleshooting

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

The `hostnames` app in the `default` namespace is reachable on its pod
IPs but not through its Service, and service names do not resolve at
all. Two breaks are planted; you do not know which.

Walk the chain from the inside out - pod, pod IP, Service and
endpoints, DNS, kube-proxy - and fix what you find. CHECK passes when
the Service has three endpoints on the right port and cluster DNS is
back.
