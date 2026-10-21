# Exercise 12 — Storage: PV, PVC, and StorageClass

Create PersistentVolumes, PersistentVolumeClaims, and mount them into pods. This covers static provisioning and StorageClass basics. You'll verify not just that the PVC binds, but that a consuming Pod can successfully schedule and use the storage.

## Tasks

1. Create a namespace called `exercise-12`
2. Create a PersistentVolume named `my-pv` with:
   - Capacity: 1Gi
   - AccessMode: ReadWriteOnce
   - StorageClass: `manual`
   - hostPath: `/data/exercise-12`
   - Reclaim policy: Retain
3. Create a PersistentVolumeClaim named `my-pvc` in namespace `exercise-12`:
   - Request: 500Mi
   - AccessMode: ReadWriteOnce
   - StorageClass: `manual`
4. Create a pod named `storage-consumer` that mounts `my-pvc` at `/data`
5. Verify:
   - The PVC is **Bound** to the PV
   - The Pod is **Running** (not stuck Pending) — the consumer Pod proves the storage is actually usable
6. Write a test file inside the mounted volume from the Pod
7. Delete the pod, create a new pod with the same PVC, and verify the file persists

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- PV is cluster-scoped (no namespace). PVC is namespace-scoped.
- The PVC binds to a PV if: capacity >= request AND accessMode matches AND storageClass matches
- **Pod scheduling:** A Pod that mounts a PVC stays Pending until the PVC is Bound. If the PVC never binds, the Pod never runs. This is how you verify end-to-end storage provisioning works.
- With `Retain`, deleting the PVC releases the PV but doesn't delete the data on disk
- With `Delete`, deleting the PVC deletes the PV and its data
- Use `k get pv`, `k get pvc -n <ns>`, and `k get pods -n <ns>` to verify all three: PV exists, PVC is Bound, Pod is Running
- **Namespace enforcement:** `my-pvc` is in `exercise-12`, so `storage-consumer` Pod must also be in `exercise-12`. Reference the PVC by name (`claimName: my-pvc`); the Pod will look for it in the same namespace.

</details>

## Verify + Cleanup

```bash
# Step 1: Verify PV exists and is available (pre-PVC-binding)
k get pv my-pv

# Step 2: Verify PVC is BOUND (this proves the binding succeeded)
k get pvc my-pvc -n exercise-12
# Status should be: Bound

# Step 3: Verify Pod is RUNNING (this proves end-to-end storage works)
k get pods -n exercise-12
# storage-consumer should be Ready 1/1 and Running

# Step 4: Verify file persists after pod recreation
k exec storage-consumer -n exercise-12 -- cat /data/test.txt

```

When done, click **CHECK**.
