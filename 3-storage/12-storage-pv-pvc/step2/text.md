# Exercise 12 — Storage: PV, PVC, and StorageClass

## Tasks

8. Delete the PVC and check PV status (should be **Released**, not Available, because policy is Retain)

## Verify + Cleanup

```bash
# Step 5: After deleting PVC, PV status should be Released (not Available)
k delete pvc my-pvc -n exercise-12
k get pv my-pv
# Status should be: Released
```

When done, click **CHECK**.
