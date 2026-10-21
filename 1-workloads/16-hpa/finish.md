## What tripped me up

> **Missing Resource Requests = Unknown Metrics (Reddit #1 HPA Complaint)**
>
> HPA showed `<unknown>/50%` for CPU and never scaled. I stared at the HPA for 5 minutes thinking the metrics-server was broken. The actual problem: my Deployment didn't have `resources.requests.cpu` set. HPA calculates percentage based on *requested* CPU. No request = no baseline = `<unknown>`. **Always set resource requests on pods that need autoscaling.** See pre-flight checklist above.

> **Target Type Must Be Utilization, Not AverageValue (Reddit #2 HPA Bug)**
>
> Created an HPA and it compiled, but `k get hpa` showed `<unknown>` metrics. When I checked the YAML with `k get hpa -o yaml`, I saw `target.type: AverageValue` instead of `target.type: Utilization`. The metrics-server can't compute AverageValue for CPU (that's for custom metrics). For CPU, must use type: `Utilization`. Check the imperative command's generated YAML carefully.

> **Scale-Down is Deliberately Slow**
>
> After I stopped generating load, replicas stayed high for 5 minutes. I thought the HPA was broken and kept restarting things. It's not broken—it's conservative. By default, HPA waits 5 minutes after load drops before scaling down (to avoid flapping). Don't panic if replicas stay high briefly after stopping load.

> **Metrics-Server Isn't Always Installed**
>
> `k top pods` returned an error. Metrics-server wasn't installed on the cluster. HPA cannot function without metrics-server (or equivalent metrics provider). On managed clusters (EKS, GKE, AKS), it's usually pre-installed. On kubeadm clusters, you have to install it manually: `k apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml`

<details>
<summary>Solution</summary>

```bash
k create ns exercise-16

# Check metrics-server
k get pods -n kube-system | grep metrics-server
k top nodes   # should return data
```

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: load-app
  namespace: exercise-16
spec:
  replicas: 1
  selector:
    matchLabels:
      app: load-app
  template:
    metadata:
      labels:
        app: load-app
    spec:
      containers:
      - name: app
        image: nginx:1.27
        resources:
          requests:
            cpu: "50m"
          limits:
            cpu: "100m"
        ports:
        - containerPort: 80
```

```bash
k apply -f deployment.yaml

# Create service
k expose deployment load-app -n exercise-16 --port=80 --target-port=80 --name=load-svc

# Option 1: Create HPA imperatively
k autoscale deployment load-app -n exercise-16 --cpu-percent=50 --min=1 --max=5

# Option 2: Create HPA declaratively (to verify structure)
k apply -f - <<EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: load-app
  namespace: exercise-16
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: load-app
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
EOF

# Verify HPA structure
k get hpa -n exercise-16 -o yaml
# Check: metrics[0].resource.target.type should be "Utilization"
# Check: metrics[0].resource.target.averageUtilization should be 50

# Generate load (run in a separate terminal)
k run load-gen -n exercise-16 --image=busybox:1.36 --rm -it -- sh -c \
  "while true; do wget -q -O- http://load-svc.exercise-16; done"

# Watch scaling in another terminal
k get hpa -n exercise-16 -w
k get pods -n exercise-16 -w

# Stop load (Ctrl+C on the load-gen terminal)
# Wait a few minutes for scale-down
```

</details>
