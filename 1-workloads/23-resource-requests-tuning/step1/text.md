# Exercise 23 — Resource Requests Tuning (Pods Won't Schedule)

Debug and fix a Deployment where pods won't schedule due to insufficient resource requests. Learn to calculate proper requests based on node capacity.

## Tasks

1. Create a namespace called `exercise-23`
2. Create a Deployment with:
   - 3 replicas
   - Image: `nginx:1.27`
   - Resource requests: 512Mi memory, 500m CPU (intentionally too high)
   - Cluster has 2 nodes with limited resources
3. Observe pods pending — they won't schedule
4. Check node capacity and available resources
5. Calculate correct resource requests to fit 3 replicas
6. Update Deployment with new (lower) requests
7. Verify all 3 pods schedule and run
8. Document the calculation

## Key Learning

The exam trick: **Do NOT use fixed rules like "10% overhead"** — calculate based on actual node allocatable resources and what's already running.

Formula:
```
Per-pod request = (Node Allocatable - System Reserved - Already Running) / Number of Replicas
Add buffer of 5-10%
```

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- `k get nodes` → see available nodes
- `k describe node <node>` → see Allocatable and Allocated resources
- `k top nodes` → see actual usage
- If pods are Pending: `k describe pod <pod>` → check Events for "Insufficient memory"
- Start with 100m CPU and 64Mi memory per replica, then adjust based on errors
- Reduce requests incrementally until all 3 pods schedule

</details>

## Verify

```bash
# Should see Pending pods with reason "Insufficient memory/cpu"
k get pods -n exercise-23

# Check why pods won't schedule
k describe pod <pod-name> -n exercise-23

# Check node capacity
k describe node <node-name>

# After fix — all 3 should be Running
k get pods -n exercise-23

# Check actual resource usage (much lower than requests)
k top pods -n exercise-23
```

When done, click **CHECK**.
