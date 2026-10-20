# Create the static pod

1. Find the kubelet's static pod directory:

   `cat /var/lib/kubelet/config.yaml | grep staticPodPath`{{exec}}

2. Create a manifest file in that directory for a pod named
   `static-web`:

   - image `nginx:1.27`
   - containerPort `80`

3. Wait a few seconds, then check the pod appears:

   `kubectl get pods | grep static-web`{{exec}}

   The pod name gets the node name appended: `static-web-controlplane`.

4. Try to delete it with kubectl and watch what happens:

   `kubectl delete pod static-web-controlplane`{{exec}}

Use this manifest:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: static-web
  labels:
    app: static-web
spec:
  containers:
  - name: web
    image: nginx:1.27
    ports:
    - containerPort: 80
```{{copy}}

When the pod is Running, click **CHECK**.
