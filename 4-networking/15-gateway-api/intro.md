# Gateway API

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready; `node01` is
reachable with `ssh node01` if you ever need it.

Gateway API splits traffic routing into a GatewayClass (which
controller), a Gateway (the listener, e.g. port 80 HTTP) and an
HTTPRoute (which path goes to which Service). A route attaches to a
Gateway through `parentRefs`.

In this exercise you create a Gateway named `web-gateway` and an
HTTPRoute named `web-route` in the `exercise-15` namespace, in front of
a `web` Deployment and its `web-svc` Service.

The Gateway API CRDs and the NGINX Gateway Fabric controller are
already installed, so a GatewayClass named `nginx` exists and will
mark your Gateway `Programmed: True`.
