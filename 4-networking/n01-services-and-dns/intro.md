# Services & DNS

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

A Service is a stable virtual IP in front of pods picked by a label
selector, and CoreDNS gives it the name
`<service>.<namespace>.svc.cluster.local`. The short name works only
from the same namespace, because the kubelet puts that namespace in
every pod's DNS search list.

In this exercise you create namespace `apps`, a pod `web`, a ClusterIP
Service `web-service` and a NodePort Service `web-nodeport` on port
30080, and test the DNS names from pods in `apps` and in `default`.
