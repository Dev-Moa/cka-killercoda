## Diagnostic: PVC Stuck in Pending (Reddit Feedback)

**Common Issue:** PVC stays `Pending` even though PV exists. Here's the decision tree:

```
1. Is PV available?
   └─ k get pv
   └─ If no PV: CREATE it first
   └─ If PV status is "Bound" → someone else claimed it, create a new PV

2. Does PVC request match PV capacity?
   └─ k describe pvc <name>
   └─ Look for "Insufficient capacity" message
   └─ PV capacity MUST be >= PVC request
   └─ If not: create bigger PV or smaller PVC request

3. Do accessModes match exactly?
   └─ k describe pv <pv-name> → shows accessModes
   └─ k describe pvc <pvc-name> → shows accessModes requested
   └─ "ReadWriteOnce" ≠ "ReadWriteMany" → must match exactly
   └─ If not: fix accessModes

4. Does storageClassName match?
   └─ k get pv <pv> → shows storageClassName
   └─ k get pvc <pvc> → shows storageClassName
   └─ BOTH must say "manual" (or same class name)
   └─ Easy to miss: one says "manual", other says "standard"
   └─ If not: make them match

5. Problems still persist?
   └─ k get events -n <ns> → look for PVC event errors
   └─ Check node: does hostPath directory exist? `ssh node; ls /data/exercise-12`
   └─ Check RBAC: does kubelet have permissions? (rare but possible)
```

**ReclaimPolicy Explained (Reddit: Often Confused)**
- `Retain`: After PVC deleted, PV becomes Released (data stays on disk)
  - Must manually delete PV or re-use it
  - Safer for static provisioning
- `Delete`: After PVC deleted, PV is automatically deleted (data destroyed)
  - Use for dynamic provisioning (StorageClass)
  - Risky for exercise: if you delete PVC, PV disappears

**Access Modes Explained (Reddit: Candidates mix these up)**
- `ReadWriteOnce (RWO)`: A volume can be mounted as read-write by a single node at a time. Multiple pods on the same node may share the same volume read-write, but it cannot be mounted read-write on two different nodes at the same time.
- `ReadWriteOncePod (RWOP)`: The volume can be mounted as read-write by only one pod, regardless of node. This is the pod-scoped exclusivity mode.
- `ReadOnlyMany (ROX)`: Multiple Pods can mount (read-only).
- `ReadWriteMany (RWX)`: Multiple Pods can mount (read+write). Requires network storage (NFS, etc).
- **Common exam mistake:** Confusing `ReadWriteOnce` with `ReadWriteOncePod`. `RWO` is node-scoped, not pod-scoped. `RWOP` is the mode that restricts access to a single pod.
- **Test this:** On the same node, two Pods can often read/write the same `ReadWriteOnce` PVC. If you need strict single-pod write access, use `ReadWriteOncePod` instead.

> **CKA note:** For Kubernetes 1.36+, the exam-safe wording is: `RWO` = one node, `RWOP` = one pod.

> **Storage Binding Requires Name Exactness**
> 
> PVC stuck in Pending for 10 minutes. I checked accessModes, checked capacity, everything matched. Turned out: my PV had `storageClassName: manual` and my PVC had `storageClassName: standard`. One word difference, no error message — just Pending forever. Always triple-check `storageClassName` matches exactly between PV and PVC. Same goes for `accessModes` — if PV is `ReadWriteMany` but PVC requests `ReadWriteOnce`, they won't bind.

> **Namespace Mismatch Breaks Pod-PVC Connection**
>
> PVC was in `default` namespace, Pod was in `exercise-12`. The PVC was Bound to the PV, so I thought everything worked. But when I created the Pod in `exercise-12`, it stayed Pending. Reason: the Pod couldn't find the PVC because they're in different namespaces. PVC and consuming Pod MUST be in the same namespace. The Pod correctly finds the PVC by name (`claimName: my-pvc`) only if they share a namespace.

> **Pod Readiness Proves Storage Works**
>
> "PVC is Bound" looks good on paper, but until you attach a Pod and it becomes Running, you haven't proven the storage actually works. A Pod staying Pending means either: (a) the PVC isn't Bound, (b) the hostPath doesn't exist on the node, (c) permissions are wrong, or (d) scheduling constraints prevent placement. Always verify the consumer Pod reaches Running state — that's your real test.

> **hostPath Directory Must Exist on Node**
>
> Created PV with `hostPath: /data/exercise-12` but forgot to `mkdir -p /data/exercise-12` on the node. Pod stayed Pending. The node has to have the backing directory, and if running on a multi-node cluster, the Pod might land on a node that doesn't have it. Consider this when designing storage tests.

> **Real cluster behavior + common failure causes**
>
> `PVC Bound` only proves the bind succeeded. It does not prove the storage is usable. The real proof is a Pod in `Running` state and a successful write/read from the mounted volume.
>
> Common causes of failure:
> - PV and PVC `accessModes` do not match exactly
> - `storageClassName` values differ (`manual` vs `standard`)
> - PVC and Pod are in different namespaces
> - the hostPath directory does not exist on the node
> - the Pod is scheduled to a node without the backing directory
> - events show a mount or scheduling issue even when the YAML looks correct
>
> Always validate with `k get pv`, `k get pvc`, `k get pod`, and `k get events` before concluding the storage setup is healthy.

<details>
<summary>Solution</summary>

```bash
k create ns exercise-12

# Create the host directory (on the node)
sudo mkdir -p /data/exercise-12
```

```yaml
# pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /data/exercise-12
```

```yaml
# pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
  namespace: exercise-12
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
  storageClassName: manual
```

```yaml
# pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: storage-consumer
  namespace: exercise-12
spec:
  containers:
  - name: consumer
    image: busybox:1.35
    command: ['sleep', '3600']  # Keeps pod running
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: my-pvc
```

```bash
k apply -f pv.yaml
k apply -f pvc.yaml

# Verify PVC is Bound BEFORE creating the Pod
k get pvc my-pvc -n exercise-12
# STATUS should be Bound

# Create the consumer Pod
k apply -f pod.yaml

# Wait for Pod to be Running (proves PVC is usable)
k get pods -n exercise-12 storage-consumer
# Should show: storage-consumer 1/1 Running

# Write a test file
k exec storage-consumer -n exercise-12 -- touch /data/test.txt
k exec storage-consumer -n exercise-12 -- sh -c 'echo "data persists" > /data/test.txt'

# Delete and recreate pod to verify persistence
k delete pod storage-consumer -n exercise-12
k apply -f pod.yaml

# Verify file persists
k exec storage-consumer -n exercise-12 -- cat /data/test.txt
# Output: data persists

# Test reclaim policy
k delete pod storage-consumer -n exercise-12
k delete pvc my-pvc -n exercise-12
k get pv my-pv
# STATUS should be Released (not Available) because policy is Retain
```

</details>
