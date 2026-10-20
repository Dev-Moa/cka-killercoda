# Create the pod with a native sidecar

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

3. Check both containers are running:

   `kubectl get pod logger -n exercise-02`{{exec}}

   The pod must show READY `2/2`.

4. Check the sidecar's logs:

   `kubectl logs logger -n exercise-02 -c log-agent`{{exec}}

   You should see the streamed output.

When done, click **CHECK**.
