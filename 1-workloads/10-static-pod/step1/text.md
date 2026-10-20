# Create the static pod

Create a static pod by placing a manifest in the kubelet's static pod
directory. Static pods are managed directly by the kubelet, not the API
server. You create the manifest yourself and place it in that directory.

1. Find the kubelet's static pod directory:

   `cat /var/lib/kubelet/config.yaml | grep staticPodPath`{{exec}}

2. Create a manifest file in that directory for a pod named
   `static-web`:

   - image `nginx:1.27`
   - containerPort `80`

3. Wait a few seconds, then check the pod appears:

   `kubectl get pods | grep static-web`{{exec}}

   The pod name gets the node name appended.

4. Try to delete the pod with kubectl and observe what happens.

When the pod is Running, click **CHECK**.
