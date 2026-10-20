# Static Pod

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

A static pod is a pod defined by a YAML file in the kubelet's manifest
directory. The kubelet watches that directory and runs whatever it
finds — no API server involved. The API server shows the pod in
`kubectl get pods`, but it cannot delete it.

In this exercise you will create a static pod, see how it behaves when
you try to delete it with kubectl, and remove it the right way.
