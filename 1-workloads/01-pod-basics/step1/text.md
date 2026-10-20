# Create the pod

A pod is the smallest unit in Kubernetes — it runs one or more
containers. In this exercise you create one pod with resource requests,
limits, and labels, then add and remove labels on the running pod. The
check looks at the exact namespace, labels, and resource values, so
small mistakes lose points.

1. Create a namespace called `exercise-01`.

2. Create a pod named `web` in the `exercise-01` namespace with:

   - Image: `nginx:1.27`
   - Labels: `app=web`, `tier=frontend`
   - Resource requests: `64Mi` memory, `100m` CPU
   - Resource limits: `128Mi` memory, `250m` CPU

3. Verify the pod is running and has the correct labels.

4. Get the pod's IP address:

   `kubectl get pod web -n exercise-01 -o wide`{{exec}}

   Look only — nothing to change.

5. Add the label `version=v1` to the running pod.

6. Remove the `tier` label from the pod.

When done, click **CHECK**.
