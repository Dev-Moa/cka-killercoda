# Exercise T05 — Container Logs

Containers log to stdout and `kubectl logs` streams that output. In a
multi-container pod the container name is mandatory — `kubectl logs
<pod>` alone errors. Logs are the first stop when an application
misbehaves.

## Tasks

Work in the `default` namespace.

1. Create a pod named `logs-demo` with two containers:
   - `sim`: image `busybox`, command
     `["sh","-c","while true; do echo \"$(date) event\"; sleep 2; done"]`
     — prints a line every 2 seconds
   - `sidecar`: image `busybox`, command `["sleep","3600"]`
2. Run `kubectl logs logs-demo` — note the error asking for a
   container name.
3. Run `kubectl logs logs-demo sim` — see the streamed lines.
4. Follow it live with `kubectl logs -f logs-demo sim`, watch two more
   lines arrive, then Ctrl+C.

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- Multi-container pod: always `kubectl logs <pod> <container>`.
- `-f` follows the stream live, like `tail -f`.
- Generate the skeleton first, then add the second container and the
  commands: `kubectl run logs-demo --image=busybox --dry-run=client
  -o yaml`.

</details>

## Verify

```bash
kubectl logs logs-demo sim      # dated lines keep appearing
kubectl logs logs-demo sidecar  # empty (sleep prints nothing) - also fine
```

When done, click **CHECK**.
