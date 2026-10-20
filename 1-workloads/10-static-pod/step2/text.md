# Remove the static pod

Deleting the pod with kubectl did not work — the kubelet recreates a
static pod the moment it disappears. The only way to remove it is to
delete the manifest file from the node.

1. Remove the manifest from the kubelet's static pod directory.

2. Wait a few seconds and confirm the pod is gone:

   `kubectl get pods | grep static-web`{{exec}}

When the pod is gone, click **CHECK**.
