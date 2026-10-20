# Multi-container Pod - done

The exam facts from this exercise:

- A native sidecar (v1.35) is an **initContainer** with
  `restartPolicy: Always` — it starts before the main container and
  keeps running next to it.
- Put the sidecar in `initContainers`, not `containers`: in
  `containers` it runs with no start-order guarantee and is not a
  native sidecar.
- Use `tail -F` (capital F), not `tail -f`: the sidecar starts before
  the app creates the log file, and `-F` waits for the file to appear.
- Both containers mount the same `emptyDir` volume named `log-volume`
  at `/var/log/app`, so the sidecar reads what the app writes.
- Verify with `kubectl get pod logger -n exercise-02` (READY `2/2`)
  and `kubectl logs logger -n exercise-02 -c log-agent` (streamed
  lines).

The exercise is based on exercise 02 in
`cka-prep/exercises/1-workloads/`.
