## Key Learning

- `WaitForFirstConsumer` = PVC stays Pending until a pod needs it
- Binding is deferred to allow node affinity scheduling
- Useful for local storage where PV is tied to a specific node
- Exam tests understanding of binding modes and their tradeoffs

## What tripped me up

> I created the PVC and expected it to be Bound immediately. It stayed Pending and I thought something was wrong. Turns out `WaitForFirstConsumer` is by design — it doesn't bind until a consumer appears. On the exam, if you see a PVC stuck in Pending, check the StorageClass binding mode. It might be intentional, not a bug. The pod has to request the PVC first, then binding happens. If the pod and PV are on different nodes, the pod won't schedule.
>
> Also: don't forget the PV needs a valid `local` path on the node, or uses a real provisioner (cloud). Without a provisioner, `WaitForFirstConsumer` + local storage is commonly tested.

<details>
<summary>Solution</summary>

```bash
k create ns exercise-25
kn exercise-25

# Create StorageClass with WaitForFirstConsumer
cat <<EOF | k apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF

# Create PersistentVolume
cat <<EOF | k apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv-1
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage
  local:
    path: /tmp/k8s-pv
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - <node-name>  # Replace with actual node name
EOF

# Get node name if needed
k get nodes -o jsonpath='{.items[0].metadata.name}'

# Verify PV created
k get pv

# Create PVC — will be Pending
cat <<EOF | k apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: local-pvc
  namespace: exercise-25
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage
  resources:
    requests:
      storage: 1Gi
EOF

# Check status — should be Pending
k get pvc

# Create Pod using PVC
cat <<EOF | k apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
  namespace: exercise-25
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sleep", "3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: local-pvc
EOF

# Now PVC should be Bound
k get pvc -w
# Watch it change from Pending to Bound

# Verify pod is running
k get pod

# Test write
k exec app-pod -n exercise-25 -- sh -c 'echo "hello" > /data/test.txt'
k exec app-pod -n exercise-25 -- cat /data/test.txt

# Cleanup
k delete ns exercise-25
k delete pv local-pv-1
k delete storageclass local-storage
```

</details>
