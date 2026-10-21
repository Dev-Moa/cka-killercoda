<details>
<summary>Solution</summary>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: logs-demo
spec:
  containers:
  - name: sim
    image: busybox
    command: ["sh","-c","while true; do echo \"$(date) event\"; sleep 2; done"]
  - name: sidecar
    image: busybox
    command: ["sleep","3600"]
```

```bash
kubectl logs logs-demo          # error: a container name must be specified
kubectl logs logs-demo sim      # the streamed lines
kubectl logs -f logs-demo sim   # follow live, Ctrl+C to stop
```

**Key insight:** one container per pod → `kubectl logs <pod>`; more
than one → the container name is mandatory. The error message tells
you that, which is the exam's way of reminding you.

</details>
