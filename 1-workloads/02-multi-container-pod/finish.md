## What tripped me up

> First attempt: I put the sidecar in `containers` instead of `initContainers`. It ran, but it wasn't a native sidecar — it started alongside the main container with no ordering guarantee. The whole point of native sidecars (v1.35) is that they start *before* the main container and keep running. Has to be `initContainers` + `restartPolicy: Always`.
>
> Second mistake: the `tail -f` command failed silently because the log file didn't exist yet. The sidecar starts first (native sidecar starts before main container), before the app container writes anything. The log file is created by the app container, so the sidecar must use `tail -F` (capital F) which waits for the file to appear and follows it through rotations.

<details>
<summary>Solution</summary>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: logger
  namespace: exercise-02
spec:
  initContainers:
  - name: log-agent
    image: busybox:1.37
    restartPolicy: Always
    command: ["sh", "-c", "tail -F /var/log/app/app.log"]
    volumeMounts:
    - name: log-volume
      mountPath: /var/log/app
  containers:
  - name: app
    image: busybox:1.37
    command: ["sh", "-c", "while true; do echo \"$(date) - app running\" >> /var/log/app/app.log; sleep 3; done"]
    volumeMounts:
    - name: log-volume
      mountPath: /var/log/app
  volumes:
  - name: log-volume
    emptyDir: {}
```

```bash
k create ns exercise-02
k apply -f logger.yaml

# Wait for pod to be ready
k get pod logger -n exercise-02 -w

# Check sidecar logs
k logs logger -n exercise-02 -c log-agent
```

</details>
