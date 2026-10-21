<details>
<summary>Solution</summary>

```bash
# 1. namespace and labeled pod
kubectl create ns apps
kubectl run web --image=nginx -l app=web -n apps

# 2. ClusterIP service; expose copies the pod labels into the selector
kubectl expose pod web --port=80 --name=web-service -n apps
kubectl get svc,endpointslices -n apps

# 3. same namespace: short name is enough
kubectl run -it --rm --restart=Never busybox --image=busybox -n apps -- sh
wget -qO- http://web-service
exit

# 4. other namespace: add the namespace, or use the full name
kubectl run -it --rm --restart=Never busybox --image=busybox -- sh
wget -qO- http://web-service                           # fails: NXDOMAIN
wget -qO- http://web-service.apps                      # works
wget -qO- http://web-service.apps.svc.cluster.local    # works
cat /etc/resolv.conf                                   # nameserver 10.96.0.10, search default.svc.cluster.local svc.cluster.local cluster.local
exit

# 5. the nameserver is the kube-dns service in front of the CoreDNS pods
kubectl get svc kube-dns -n kube-system
kubectl get pods -n kube-system -l k8s-app=kube-dns

# 6. NodePort: generate with expose, add the nodePort, create
kubectl expose pod web --type=NodePort --port=80 --name=web-nodeport -n apps --dry-run=client -o yaml > np.yaml
vi np.yaml
```

```yaml
  ports:
  - port: 80            # on the service
    targetPort: 80      # on the pod
    nodePort: 30080     # on every node
```

```bash
kubectl create -f np.yaml
kubectl get nodes -o wide                              # INTERNAL-IP
curl http://<node-ip>:30080
```

**Key insight:** a service is a virtual IP that kube-proxy turns into
node rules, and a DNS record `name.namespace.svc.cluster.local` that
CoreDNS serves. The short name works only because the kubelet writes
the pod's own namespace into the search list. No endpoint means the
selector does not match the pod labels.

</details>
