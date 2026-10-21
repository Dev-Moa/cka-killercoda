# Complex NetworkPolicy

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

A NetworkPolicy lives in one namespace and selects pods there. To let
traffic in from another namespace you select that namespace by label
with `namespaceSelector`, so the namespaces need labels first.

In this exercise you build three namespaces (`frontend`, `backend`,
`database`), one pod per tier, and the policies that allow only
frontend to backend on 8080 and backend to database on 6379, with DNS
egress open everywhere.

Whether the policies are enforced depends on the cluster's CNI plugin.
CHECK grades the policy specs and the pod labels, not blocked traffic.
