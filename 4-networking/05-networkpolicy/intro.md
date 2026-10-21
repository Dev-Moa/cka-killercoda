# NetworkPolicy

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

A NetworkPolicy selects pods by label and lists the traffic they may
receive (ingress) and send (egress). Once a pod is selected by any
policy, everything the policy does not allow is dropped.

In this exercise you run three pods in the `exercise-05` namespace and
write one policy on the backend pod: ingress only from the frontend on
port 80, plus the DNS egress rule that everyone forgets.

Whether the policy is enforced depends on the cluster's CNI plugin.
CHECK grades the policy's spec, so the connectivity tests in Verify are
for you, not for the grader.
