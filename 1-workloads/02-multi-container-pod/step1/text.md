# Exercise 02 — Multi-Container Pod (Sidecar Logging)

Create a pod with a main container and a sidecar container that tails the main container's log file. This uses the v1.35 native sidecar container feature (`restartPolicy: Always` on an init container).

## Tasks

1. Create a namespace called `exercise-02`
2. Create a pod named `logger` in namespace `exercise-02` with:
   - An init container (sidecar) named `log-agent` using `busybox:1.36`
     - Set `restartPolicy: Always` on the init container to make it a native sidecar
     - Command: `tail -F /var/log/app/app.log` (capital F waits for file creation)
     - Mount a shared volume at `/var/log/app`
   - A main container named `app` using `busybox:1.36`
     - Command: write a line to `/var/log/app/app.log` every 3 seconds
     - Mount the same shared volume at `/var/log/app`
   - Use an `emptyDir` volume named `log-volume`
3. Verify both containers are running
4. Check the sidecar's logs to see the streamed output

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- Native sidecars in v1.35: put the sidecar in `initContainers` with `restartPolicy: Always`
- The sidecar starts before the main container and keeps running alongside it
- Shared volume: both containers mount the same `emptyDir`

</details>

## Verify

```bash
# Both containers should be Running (READY 2/2)
k get pod logger -n exercise-02

# Should see the log lines from the app container
k logs logger -n exercise-02 -c log-agent
```

When done, click **CHECK**.
