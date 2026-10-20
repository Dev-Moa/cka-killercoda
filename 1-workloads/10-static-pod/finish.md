# Static Pod - done

The exam facts from this exercise:

- Static pods are managed by the **kubelet**, not the API server.
- The manifest directory is `staticPodPath` in
  `/var/lib/kubelet/config.yaml` — usually `/etc/kubernetes/manifests`.
- `kubectl delete pod` does not work: the kubelet recreates the pod.
- To remove a static pod, delete the manifest file from the node.
- The pod name gets the node name appended: `static-web-controlplane`.
- Give the kubelet a few seconds to pick up or drop a manifest.

The exercise is based on the static pod note in `notes/2-Scheduling/27`
and exercise 10 in `cka-prep/exercises/1-workloads/`.
