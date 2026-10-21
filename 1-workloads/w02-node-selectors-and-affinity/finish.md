<details>
<summary>Solution</summary>

```bash
# 1. labels on the node
kubectl get node <worker> --show-labels

# 2. label it
kubectl label nodes <worker> size=Large

# 3. pod with nodeSelector: generate, edit, create
kubectl run data-processor --image nginx --dry-run=client -o yaml > dp.yaml
vi dp.yaml
```

Add under `spec`, same level as `containers`:

```yaml
nodeSelector:
  size: Large
```

```bash
kubectl create -f dp.yaml
kubectl get pod data-processor -o wide

# 4. second label
kubectl label nodes <worker> color=blue

# 5. deployment; with no taints its pods may land on any node
kubectl create deployment blue --image=nginx --replicas=3
kubectl describe nodes | grep -i taint
kubectl get pods -o wide

# 6. edit in place; the edit rolls the pods out again
kubectl edit deployment blue
```

Add under `spec.template.spec`, same level as `containers`:

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: color
          operator: In
          values:
          - blue
```

```bash
kubectl get pods -l app=blue -o wide

# 7. generate, add affinity with Exists, create
kubectl create deployment red --image=nginx --replicas=2 --dry-run=client -o yaml > red.yaml
vi red.yaml
```

Add under `spec.template.spec`:

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: node-role.kubernetes.io/control-plane
          operator: Exists
```

```bash
kubectl create -f red.yaml
kubectl get pods -l app=red -o wide
```

**Key insight:** `nodeSelector` is one label with one value. Node
affinity adds operators: `In` (one of these values), `NotIn` (none of
these), `Exists` (label present, any value). `required...` means the
pod stays Pending if no node matches; `preferred...` means the
scheduler tries, then places it anywhere. `IgnoredDuringExecution`
means a label change later does not move a running pod.

</details>
