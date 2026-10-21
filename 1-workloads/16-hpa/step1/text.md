# Exercise 16 — Horizontal Pod Autoscaler

Configure a Horizontal Pod Autoscaler to scale a deployment based on CPU usage. Also understand Vertical Pod Autoscaler for resource optimization. This requires the metrics-server to be installed in the cluster.

## Context: HPA vs VPA

## Context: HPA vs VPA

HPA (Horizontal Pod Autoscaler) scales the number of replicas based on metrics like CPU or memory. When CPU exceeds target, HPA creates more pods. When load drops, it removes pods.

VPA (Vertical Pod Autoscaler) adjusts the CPU and memory requests/limits for existing pods based on actual usage. If a pod requests 256Mi memory but only uses 64Mi, VPA recommends lowering the request. This doesn't scale replicas; it optimizes resource allocation to improve bin-packing and reduce waste.

The CKA focuses on HPA, but understanding VPA helps with cluster resource efficiency.

## Tasks (HPA)

1. Create a namespace called `exercise-16`
2. Verify the metrics-server is running in the cluster
3. Create a Deployment named `load-app` with:
   - Image: `registry.k8s.io/hpa-example` (or `nginx:1.27` with resource requests)
   - 1 replica
   - CPU request: 50m
   - CPU limit: 100m
4. Expose it with a ClusterIP Service named `load-svc` on port 80
5. Create an HPA targeting `load-app`:
   - Min replicas: 1
   - Max replicas: 5
   - **Target CPU utilization: 50%** (must be specified as `type: Utilization` with `averageUtilization: 50`)
6. Verify the HPA YAML has correct structure (target type is `Utilization`, not `AverageValue`)
7. Generate load against the service and observe the HPA scaling up
8. Stop the load and observe the HPA scaling back down

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- `k top pods -n exercise-16` to check if metrics-server is working
- `k autoscale deployment load-app --cpu-percent=50 --min=1 --max=5` creates a basic HPA
- **Verify HPA structure:** After creating the HPA, run `k get hpa -n exercise-16 -o yaml` and check that:
  - `spec.metrics[0].type` == `Resource`
  - `spec.metrics[0].resource.target.type` == `Utilization` (not `AverageValue`)
  - `spec.metrics[0].resource.target.averageUtilization` == 50
- Load generation: `k run load-gen --image=busybox:1.36 --rm -it -- sh -c "while true; do wget -q -O- http://load-svc.exercise-16; done"`
- Scale down takes a few minutes after load stops (by design, to avoid flapping)

**HPA Pre-Flight Checklist (Reddit: This solves 80% of HPA issues)**
```bash
# 1. Is metrics-server running?
k get deployment -n kube-system metrics-server
# If not running: might be missing from cluster; install via init-cluster.sh

# 2. Does `kubectl top` work?
k top nodes
k top pods -n exercise-16
# If "metrics not available": wait 60 seconds (metrics collection delay)

# 3. Does Deployment have resource requests?
k get deployment load-app -n exercise-16 -o json | jq '.spec.template.spec.containers[0].resources'
# Must show: "requests": {"cpu": "50m"} (or similar value)
# If empty {}: **This is why HPA shows <unknown>**, add requests to deployment

# 4. Is HPA watching the right target.type?
k get hpa -n exercise-16 -o yaml | grep -A5 "metrics:"
# Must show: type: Utilization (NOT AverageValue or cpu)
# If wrong: recreate HPA with: k autoscale deployment load-app --cpu-percent=50

# 5. Is HPA showing valid metrics?
k get hpa -n exercise-16
# Should show: TARGETS "X%/50%" or "100m/50m"
# If "unknown/50%": problem is Deployment has no resource.requests
```

**Target Type vs. Target Value (Commonly Confused)**
- `type: Utilization` + `averageUtilization: 50` = Scale when 50% of *requested* CPU in use
  - Example: Pod requests 100m CPU, use 50m → 50% = scale trigger
  - **This is what most exams test**
- `type: Value` + `averageValue: 50m` = Scale when average pod uses exactly 50m CPU
  - Less common; requires knowing absolute metrics in advance
- **Exam gotcha:** Using `type: Value` when question implies `Utilization` → HPA never scales

</details>

## Verify

```bash
# HPA created
k get hpa -n exercise-16

# Under load: replicas should increase
k get hpa -n exercise-16 -w

# Pods scaling
k get pods -n exercise-16 -w
```

When done, click **CHECK**.
