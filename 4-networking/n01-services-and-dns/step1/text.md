# Exercise N01 — Services and DNS

Expose a pod with a ClusterIP and a NodePort service, then prove the
DNS names work from another pod in the same and in a different
namespace. This tests the three ports, the selector-to-label link, and
the `name.namespace.svc.cluster.local` record.

## Tasks

1. Create namespace `apps`. In it, run a pod named `web` with image
   `nginx` and label `app=web`.
2. Expose `web` as a ClusterIP service named `web-service` on port 80
   in namespace `apps`. Confirm the service has an endpoint.
3. From a temporary `busybox` pod in namespace `apps`, reach the
   service by its short name.
4. From a temporary `busybox` pod in namespace `default`, reach the
   service. The short name must fail and the namespaced name must work.
   Also try the full name.
5. Look at `/etc/resolv.conf` inside a pod and explain where the
   nameserver IP comes from. Find the service in `kube-system` that owns
   that IP.
6. Create a second service named `web-nodeport` of type NodePort for
   the same pod, on node port `30080`. Reach it from the node.

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- `kubectl run web --image=nginx -l app=web -n apps` sets the label at
  create time.
- `kubectl expose pod web ...` takes the pod's labels as the selector.
  `kubectl create service nodeport ...` can set `--node-port` but has
  no selector flag, so generate with `expose --type=NodePort
  --dry-run=client -o yaml` and add `nodePort: 30080` in the file.
- A temporary test pod: `kubectl run -it --rm --restart=Never busybox
  --image=busybox -n <ns> -- sh`, then `wget -qO- http://<name>`.
- DNS names: `web-service` works only in the same namespace.
  `web-service.apps` and `web-service.apps.svc.cluster.local` work
  from anywhere.
- `kubectl get svc -n kube-system` shows `kube-dns`. Its ClusterIP is
  the nameserver the kubelet writes into every pod.

</details>

## Verify

```bash
kubectl get svc -n apps                                              # web-service ClusterIP :80, web-nodeport NodePort 80:30080
kubectl get endpointslices -n apps -l kubernetes.io/service-name=web-service   # one endpoint = the pod IP
kubectl get svc kube-dns -n kube-system                              # ClusterIP matches nameserver in resolv.conf
curl http://<node-ip>:30080                                          # nginx welcome page from the node
```

When done, click **CHECK**.
