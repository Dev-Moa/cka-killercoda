# Application Failure

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

A two-tier app in the `shop` namespace is broken in three places. One
Service answers nobody, one pod keeps restarting, and one pod never
starts. The breaks are already planted; you do not know which.

Walk the chain the exam way - Service, endpoints, pod, logs - and fix
all three without deleting the Service. CHECK passes when the Service
has an endpoint and answers, and every pod in `shop` is Running.
