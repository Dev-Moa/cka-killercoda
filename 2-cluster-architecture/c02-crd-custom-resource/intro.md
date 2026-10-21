# CRD and Custom Resource

You are root on controlplane of a two-node kubeadm cluster; kubectl is
ready and node01 is reachable with `ssh node01` if you ever need it.

A CustomResourceDefinition (CRD) teaches the API server a new resource
kind. You will inspect the CRDs already in the cluster, create the
`CronTab` CRD from the docs example, make one object of the new kind in
the `default` namespace, and then delete the CRD again.
