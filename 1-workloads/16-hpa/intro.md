# HPA

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

A HorizontalPodAutoscaler (HPA) adds or removes pod replicas based on
CPU or memory use. For the HPA to work, the metrics-server must run and
the Deployment's pods must set a CPU request.

In this exercise you will create a Deployment with a CPU request, expose
it with a ClusterIP Service, and add an HPA that scales on CPU. All work
happens in the `exercise-16` namespace, which already exists.
