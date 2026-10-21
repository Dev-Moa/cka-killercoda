# Exercise T03 — Network Troubleshooting

Walk the network chain from the inside out: pod → pod IP → Service and
endpoints → DNS → kube-proxy. Two breaks are planted: a wrong
`targetPort` and a scaled-down CoreDNS. Fix them in chain order.

## Tasks

1. Check the `hostnames` pods are healthy. Reach one of them directly
   on its pod IP and port from a test pod.
2. Reach `hostnames` through the Service by its ClusterIP. It fails.
   Find out why from the Service and its endpoints, and fix it.
3. Reach `hostnames` by name. It fails. Find out why in `kube-system`
   and fix it. Confirm `nslookup` works from a pod.
4. Check kube-proxy: one pod per node, Running, and the proxy mode in
   its ConfigMap.

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- The app in `serve_hostname` listens on 9376. Inside a busybox pod:
  `wget -qO- http://<pod-ip>:9376`.
- `kubectl get endpointslices -l kubernetes.io/service-name=hostnames`.
  Endpoints with the wrong port, or none at all, mean `targetPort` or
  the selector. `kubectl edit svc hostnames` fixes it.
- `nslookup hostnames` failing while the ClusterIP works means DNS.
  `kubectl get pods -n kube-system -l k8s-app=kube-dns` shows no pods.
  `kubectl get deploy coredns -n kube-system` shows 0/0.
- Pod `/etc/resolv.conf` must point at the `kube-dns` ClusterIP.
- kube-proxy mode: `kubectl get cm kube-proxy -n kube-system -o yaml
  | grep mode`.

</details>

## Verify

```bash
kubectl get endpointslices -l kubernetes.io/service-name=hostnames      # three endpoints, port 9376
kubectl run -it --rm --restart=Never t --image=busybox -- wget -qO- http://hostnames   # a pod hostname
kubectl get pods -n kube-system -l k8s-app=kube-dns                     # CoreDNS Running
kubectl get pods -n kube-system -l k8s-app=kube-proxy -o wide           # one per node, Running
```

When done, click **CHECK**.
