# RBAC

You are root on controlplane of a two-node kubeadm cluster; kubectl is
ready and node01 is reachable with `ssh node01` if you ever need it.

This exercise builds Role-Based Access Control for a ServiceAccount: a
Role and RoleBinding in namespace `exercise-04`, then a ClusterRole
and ClusterRoleBinding so the same ServiceAccount can list nodes.
