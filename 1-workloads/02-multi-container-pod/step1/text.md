A native sidecar (v1.35) is an init container with
`restartPolicy: Always`: it starts before the main container and keeps
running next to it for the pod's whole life. Here one container writes
a log line every 3 seconds and the sidecar tails the same file through
a shared `emptyDir` volume — the classic sidecar logging pattern the
exam tests. The trap: the sidecar must go in `initContainers`, not
`containers`, or it loses its start-order guarantee.

Create a pod with a main container and a native sidecar that tails the
main container's log file.

1. Create a namespace called `exercise-02`.

2. Create a pod named `logger` in the `exercise-02` namespace with:

   - A native sidecar: an init container named `log-agent` using
     `busybox:1.36` with `restartPolicy: Always`, command
     `tail -F /var/log/app/app.log` (capital F waits for the file to
     appear), and a shared volume mounted at `/var/log/app`
   - A main container named `app` using `busybox:1.36` that writes a
     line to `/var/log/app/app.log` every 3 seconds and mounts the
     same shared volume at `/var/log/app`
   - An `emptyDir` volume named `log-volume` shared by both containers

3. Verify both containers are running (READY 2/2).

4. Check the sidecar's logs with
   `kubectl logs logger -n exercise-02 -c log-agent`{{exec}} — you
   should see the streamed output.

If CHECK fails without showing why, read the full report:
`cat /tmp/check-report.txt`{{exec}}

When done, click **CHECK**.
