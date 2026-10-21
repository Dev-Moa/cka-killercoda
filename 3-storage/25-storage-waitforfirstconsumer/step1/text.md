# Exercise 25 — Storage with WaitForFirstConsumer Binding

Create a StorageClass with `WaitForFirstConsumer` binding mode, and understand why PVCs remain Pending until a pod actually uses them.

## Tasks

1. Create a namespace called `exercise-25`
2. Create a StorageClass named `local-storage` with:
   - Provisioner: `kubernetes.io/no-provisioner` (local volumes)
   - Binding mode: `WaitForFirstConsumer`
3. Create a PersistentVolume (PV) with:
   - Name: `local-pv-1`
   - Size: 1Gi
   - AccessMode: ReadWriteOnce
   - StorageClassName: `local-storage`
   - Local path: `/tmp/k8s-pv` (or any valid node path)
4. Create a PersistentVolumeClaim (PVC) with:
   - Name: `local-pvc`
   - Size: 1Gi
   - StorageClassName: `local-storage`
5. Observe: PVC remains Pending (not Bound) — WHY?
6. Create a Pod that uses the PVC:
   - Image: `busybox:1.36`
   - Mount PVC at `/data`
7. Observe: Now PVC transitions to Bound
   - Pod schedules on the node where the PV exists
8. Verify data persistence by writing to the volume

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- PVC should show `Pending` initially, not `Bound`
- Once pod is created using PVC, PVC transitions to `Bound`
- Pod scheduling respects the PV node affinity
- `k get pvc -w` to watch the status change

</details>

## Verify

```bash
# Initially: PVC should be Pending
k get pvc -n exercise-25

# After pod creation: PVC should be Bound
k get pvc -n exercise-25

# Pod should be Running
k get pod -n exercise-25

# Verify mount inside pod
k exec -it <pod> -n exercise-25 -- ls /data

# Write test data
k exec -it <pod> -n exercise-25 -- sh -c 'echo "test data" > /data/test.txt'

# Read it back
k exec -it <pod> -n exercise-25 -- cat /data/test.txt
```

When done, click **CHECK**.
