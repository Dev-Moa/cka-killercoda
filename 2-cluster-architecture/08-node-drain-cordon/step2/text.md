## Tasks

7. Uncordon the node
8. Scale the deployment to 6 replicas and verify pods get scheduled on the uncordoned node

## Verify

```bash
# After uncordon + scale
k get pods -o wide
# Pods should spread across nodes again
```

When done, click **CHECK**.
