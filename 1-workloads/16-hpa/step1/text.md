# Create the deployment, service, and HPA

HPA (Horizontal Pod Autoscaler) scales the number of replicas based on
metrics like CPU or memory: when CPU use goes above the target, it
creates more pods; when load drops, it removes pods. VPA (Vertical Pod
Autoscaler) adjusts the CPU and memory requests of existing pods
instead — it does not scale replicas. The CKA focuses on HPA, so this
exercise is about a Deployment with a CPU request and an HPA that
scales it on CPU utilization.

The `exercise-16` namespace already exists. Do all work in it.

1. Verify the metrics-server works:

   `kubectl top nodes`{{exec}}

   It should return data. It may take about a minute after the cluster
   starts. The HPA needs it.

2. Create a Deployment named `load-app` in `exercise-16` with `1`
   replica, image `nginx:1.27`, CPU request `50m`, and CPU limit `100m`.

3. Expose the Deployment with a ClusterIP Service named `load-svc` on
   port `80`.

4. Create a HorizontalPodAutoscaler named `load-app` targeting
   Deployment `load-app`: minReplicas `1`, maxReplicas `5`, target CPU
   utilization `50%`. The target MUST be `type: Utilization` with
   `averageUtilization: 50` - do NOT use `AverageValue`.

5. Check the HPA YAML to confirm the metric target type is
   `Utilization`.

6. Generate load against the service (for example a busybox pod running
   `while true; do wget -q -O- http://load-svc.exercise-16; done`) and
   watch the HPA scale up. Metrics take about a minute to appear, and
   scale-down after the load stops is slow on purpose (about 5 minutes)
   - do not wait for it.

7. Stop the load when you are done.

When done, click **CHECK**.
