<details>
<summary>Solution</summary>

```bash
# 1. metrics server present
kubectl get pods -n kube-system | grep metrics

# 2-3. node metrics (wait a minute on a fresh cluster)
kubectl top node

# 4. pod metrics
kubectl create deployment load --image=nginx
kubectl get pods -w          # wait for Running
kubectl top pod
```

**Key insight:** `kubectl top node` for the nodes, `kubectl top pod`
for pods. No data right after cluster start is not a failure — the
Metrics Server needs time to collect. If it still fails, the
metrics-server pod is the place to look.

</details>
