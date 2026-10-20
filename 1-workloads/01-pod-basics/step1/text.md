# Create the pod

1. Create a namespace called `exercise-01`:

   `kubectl create namespace exercise-01`{{exec}}

2. Create a pod named `web` in the `exercise-01` namespace with:

   - image `nginx:1.27`
   - labels `app=web`, `tier=frontend`
   - resource requests: `64Mi` memory, `100m` CPU
   - resource limits: `128Mi` memory, `250m` CPU

3. Verify the pod is Running and has the correct labels:

   `kubectl get pod web -n exercise-01 --show-labels`{{exec}}

4. Get the pod's IP address:

   `kubectl get pod web -n exercise-01 -o wide`{{exec}}

   Look only — nothing to change.

5. Add the label `version=v1` to the running pod:

   `kubectl label pod web -n exercise-01 version=v1`{{exec}}

6. Remove the `tier` label from the pod:

   `kubectl label pod web -n exercise-01 tier-`{{exec}}

Use this manifest:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web
  namespace: exercise-01
  labels:
    app: web
    tier: frontend
spec:
  containers:
  - name: web
    image: nginx:1.27
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "250m"
```{{copy}}

When done, click **CHECK**.
