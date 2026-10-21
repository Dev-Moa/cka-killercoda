# Container Logs

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

Containers write to stdout and `kubectl logs` reads it. With two
containers in a pod, the container name is mandatory. Nothing is
broken.

You create a two-container pod named `logs-demo` in the `default`
namespace and read one container's log stream. CHECK passes when the
pod is Running with both containers and the `sim` container has
written log lines.
