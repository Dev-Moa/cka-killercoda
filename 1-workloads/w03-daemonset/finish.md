<details>
<summary>Solution</summary>

```bash
# 1. existing DaemonSets; kube-proxy is one, DESIRED = number of nodes
kubectl get daemonsets -A

# 2. generate a deployment skeleton and turn it into a DaemonSet
kubectl create deployment monitoring-daemon --image=nginx --dry-run=client -o yaml > ds.yaml
vi ds.yaml
```

Change `kind: Deployment` to `kind: DaemonSet`, delete the `replicas`
line and the `strategy` block if present, and set the labels in both
places to `app: monitoring-agent`. The result:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: monitoring-daemon
spec:
  selector:
    matchLabels:
      app: monitoring-agent
  template:
    metadata:
      labels:
        app: monitoring-agent
    spec:
      containers:
      - name: nginx
        image: nginx
```

```bash
kubectl create -f ds.yaml

# 3. one pod per worker; the control plane is tainted, so no pod there
kubectl get pods -l app=monitoring-agent -o wide
kubectl describe node <controlplane> | grep Taint
# Taints: node-role.kubernetes.io/control-plane:NoSchedule

# 4. add a toleration under template.spec, then apply
vi ds.yaml
```

```yaml
    spec:
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      containers:
      - name: nginx
        image: nginx
```

```bash
kubectl apply -f ds.yaml

# 5. one pod on every node now
kubectl get pods -l app=monitoring-agent -o wide
kubectl get ds monitoring-daemon
```

**Key insight:** a DaemonSet is a ReplicaSet whose count is "one per
node", so there is no `replicas` field. It uses the default scheduler,
so taints apply to it like to any pod. To reach a tainted control
plane node the template needs a toleration, exactly as kube-proxy's
does.

</details>
