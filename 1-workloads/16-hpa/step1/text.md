# Create the deployment, service, and HPA

The `exercise-16` namespace already exists. Do all work in it.

1. Verify the metrics-server works:

   `kubectl top nodes`{{exec}}

   It should return data. It may take about a minute after the cluster
   starts. The HPA needs it.

2. Create a Deployment named `load-app` in `exercise-16` with `1`
   replica, image `nginx:1.27`, CPU request `50m`, and CPU limit `100m`:

   `kubectl create deployment load-app -n exercise-16 --image=nginx:1.27 --replicas=1`{{exec}}

   `kubectl set resources deployment load-app -n exercise-16 -c=nginx --requests=cpu=50m --limits=cpu=100m`{{exec}}

3. Expose the Deployment with a ClusterIP Service named `load-svc` on
   port `80`:

   `kubectl expose deployment load-app -n exercise-16 --port=80 --target-port=80 --name=load-svc`{{exec}}

4. Create a HorizontalPodAutoscaler named `load-app` targeting
   Deployment `load-app`: minReplicas `1`, maxReplicas `5`, target CPU
   utilization `50%`. The target MUST be `type: Utilization` with
   `averageUtilization: 50` — do NOT use `AverageValue`.

   `kubectl autoscale deployment load-app -n exercise-16 --cpu-percent=50 --min=1 --max=5`{{exec}}

5. Check the HPA YAML to confirm the metric target type is
   `Utilization`:

   `kubectl get hpa load-app -n exercise-16 -o yaml`{{exec}}

6. Generate load against the service and watch the HPA scale up:

   ```bash
   kubectl run load-gen -n exercise-16 --image=busybox:1.36 --rm -it -- sh -c "while true; do wget -q -O- http://load-svc.exercise-16; done"
   ```{{copy}}

   Metrics take about a minute to appear. Scale-down after the load
   stops is slow on purpose (about 5 minutes) — do not wait for it.

7. Stop the load when you are done (Ctrl+C on the `load-gen` pod).

Use these manifests instead of the imperative commands above:

```yaml
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
```{{copy}}

```yaml
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
```{{copy}}

When done, click **CHECK**.
