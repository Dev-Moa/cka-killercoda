# Classic Ingress

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

An Ingress is a set of HTTP routing rules (host, path, backend
Service) that an Ingress controller turns into real proxy config. With
no controller the object is accepted but nothing routes and no ADDRESS
appears.

In this exercise you create two Deployments and Services in the
`exercise-19` namespace and one Ingress named `app-ingress` that sends
`/` to `web-service:80` and `/api` to `api-service:8080`.

The ingress-nginx controller is already installed (namespace
`ingress-nginx`, IngressClass `nginx`), so use `ingressClassName:
nginx`.
