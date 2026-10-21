## What tripped me up

> I used the standard "reserve 10% per node" rule and pods still didn't schedule. Turns out on the lab cluster, nodes had way more system pods running. I wasted 8 minutes before checking `k describe node` to see actual allocatable vs allocated. The real exam has variable node sizes and random system pods — you MUST verify actual capacity, not assume. Then divide evenly across replicas, not just apply a formula.
>
> Also: resource requests are hard limits for scheduling. If a pod requests 512Mi and node has only 256Mi free, it will NEVER schedule, even if the pod only uses 10Mi at runtime. Requests are for the scheduler, not for actual usage. On the exam, if pods won't schedule, first check if requests are too high via `k describe node`.

<details>
<summary>Solution</summary>

```bash
k create ns exercise-23
kn exercise-23

# Create deployment with too-high requests (will fail to schedule)
k create deployment web --image=nginx:1.27 --replicas=3 $do > deploy.yaml
```

Edit `deploy.yaml` to add initial (intentionally high) requests:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: exercise-23
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:1.27
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
```

```bash
k apply -f deploy.yaml

# Check pods — they are Pending
k get pods

# Describe to see error
k describe pod <pod-name>
# Output: "Insufficient memory"

# Check node capacity
k describe node <node-name>
# Allocatable:  2000m (CPU)
#              2Gi (Memory)
# With 3 replicas, need to divide available resources

# Calculate: If node has 2Gi available and 2 cores (2000m)
# Per pod: ~600Mi memory and 600m CPU (with overhead)
# But if already running system pods, reduce further

# Edit deploy.yaml with lower values
```

Fix the requests to something realistic:

```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
```

```bash
k apply -f deploy.yaml

# Verify all 3 pods now Running
k get pods -n exercise-23

# Check actual usage (will be much lower than requests)
k top pods -n exercise-23

# Cleanup
k delete ns exercise-23
```

</details>
