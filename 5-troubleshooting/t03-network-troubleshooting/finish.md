## Setup

```bash
kubectl create deployment hostnames --image=registry.k8s.io/serve_hostname --replicas=3
kubectl expose deployment hostnames --port=80 --target-port=9377          # break 1: app listens on 9376
kubectl scale deployment coredns -n kube-system --replicas=0              # break 2: no DNS
```

<details>
<summary>Solution</summary>

```bash
# 1. pod health, then the pod IP directly
kubectl get pods -l app=hostnames -o wide
kubectl run -it --rm --restart=Never t --image=busybox -- sh
wget -qO- http://<pod-ip>:9376                  # answers with the pod name
wget -qO- http://<service-cluster-ip>            # hangs: the Service is broken
exit

# 2. Service vs endpoints
kubectl get svc hostnames -o yaml | grep -A3 ports          # targetPort: 9377
kubectl get endpointslices -l kubernetes.io/service-name=hostnames -o yaml | grep port   # 9377, nothing listens there
kubectl edit svc hostnames                                   # targetPort: 9376
kubectl run -it --rm --restart=Never t --image=busybox -- wget -qO- http://<service-cluster-ip>   # works

# 3. by name: DNS
kubectl run -it --rm --restart=Never t --image=busybox -- nslookup hostnames   # timeout
kubectl get pods -n kube-system -l k8s-app=kube-dns          # no pods
kubectl get deploy coredns -n kube-system                    # 0/0
kubectl scale deployment coredns -n kube-system --replicas=2
kubectl get endpointslices -n kube-system -l kubernetes.io/service-name=kube-dns   # two endpoints
kubectl run -it --rm --restart=Never t --image=busybox -- sh
cat /etc/resolv.conf                                         # nameserver = kube-dns ClusterIP
nslookup hostnames                                           # resolves
wget -qO- http://hostnames                                   # works
exit

# 4. kube-proxy
kubectl get pods -n kube-system -l k8s-app=kube-proxy -o wide
kubectl logs -n kube-system <kube-proxy-pod> | tail          # syncing rules, no errors
kubectl get cm kube-proxy -n kube-system -o yaml | grep mode
```

**Key insight:** if the pod answers on its own IP but not through the
Service, the fault is the Service, DNS or kube-proxy, never the app.
Endpoints tell you selector and `targetPort` at once. CoreDNS lives in
`kube-system` behind the `kube-dns` Service, and the kubelet writes
that Service's IP into every pod's `resolv.conf`.

</details>
