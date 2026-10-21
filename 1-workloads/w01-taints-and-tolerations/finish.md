<details>
<summary>Solution</summary>

```bash
# 1. look for the Taints line
kubectl describe node <worker> | grep Taint

# 2. taint the node: key=value:effect
kubectl taint nodes <worker> spray=mortein:NoSchedule

# 3. plain pod: it stays Pending, no node accepts it
kubectl run mosquito --image nginx
kubectl get pods

# 4. pod with a toleration: generate, edit, create
kubectl run bee --image nginx --dry-run=client -o yaml > bee.yaml
vi bee.yaml
```

Add under `spec`, at the same level as `containers`:

```yaml
tolerations:
- key: spray
  operator: Equal
  value: mortein
  effect: NoSchedule
```

```bash
kubectl create -f bee.yaml
kubectl get pods -o wide

# 5. control plane taint
kubectl describe node <controlplane> | grep Taint

# 6. remove it with a trailing "-"; mosquito schedules there
kubectl taint nodes <controlplane> node-role.kubernetes.io/control-plane:NoSchedule-
kubectl get pods -o wide

# 7. put it back
kubectl taint nodes <controlplane> node-role.kubernetes.io/control-plane:NoSchedule
```

**Key insight:** a taint does not send a pod to a node. It only lets the
node refuse pods that do not tolerate it. `NoSchedule` blocks new pods,
`NoExecute` also evicts running ones, `PreferNoSchedule` is only a
preference.

</details>
