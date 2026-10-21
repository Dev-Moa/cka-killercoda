# Exercise 10 — Static Pod

Create a static pod by placing a manifest in the kubelet's static pod directory. Static pods are managed directly by the kubelet, not the API server.

## Tasks

1. Find the static pod manifest directory on the node
2. Create a static pod manifest file for a pod named `static-web` with:
   - Image: `nginx:1.27`
   - Port: 80
3. Verify the static pod appears in `k get pods` (it will have the node name appended)
4. Try to delete the static pod with `kubectl` — observe what happens

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- The static pod path is configured in the kubelet config, usually `/etc/kubernetes/manifests/`
- Check kubelet config: `cat /var/lib/kubelet/config.yaml | grep staticPodPath`
- Static pods show up in `kubectl` but can't be deleted through the API — the kubelet recreates them
- The pod name will be `static-web-<node-name>`

</details>

## Verify

```bash
# Should show static-web-<node>
k get pods -A | grep static-web

# Describe should show the static pod
k describe pod static-web-<node> -n default
```

When done, click **CHECK**.
