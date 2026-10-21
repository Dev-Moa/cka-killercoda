# Exercise T01 — Application Failure

A two-tier app is broken in three places. You plant the breaks
yourself in the setup, then fix them in the same order you would on
the exam: Service → endpoints → pod → logs. Because you know the
breaks, this is a redo drill. For the real surprise, do the KodeKloud
"Application Failure" practice test first.

## Tasks

1. A user reports that `web-service` in namespace `shop` does not
   answer. Find why and fix it without deleting the service. Prove it
   answers from a test pod.
2. The pod `db` keeps restarting. Find the reason in its logs and fix
   it so it stays Running. The fix may recreate the pod.
3. The pod `cache` never starts. Find the reason in its events and fix
   it so it runs `redis` (any working tag).
4. List all events in the namespace sorted by time and confirm no new
   errors appear.

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- `kubectl describe svc web-service -n shop`: read `Selector` and
  `Endpoints`. Empty endpoints means the selector does not match the
  pod labels. Compare with `kubectl get pods -n shop --show-labels`.
- A crashing container has no logs yet. `kubectl logs db -n shop -p`
  shows the previous one. The error says what is missing.
- `kubectl describe pod cache -n shop`: the Events table at the bottom
  says `ErrImagePull` / `ImagePullBackOff` and names the tag.
- `kubectl set image pod/cache cache=redis -n shop` changes an image in
  place. For the env var on `db`, recreate the pod with
  `--env=MYSQL_ROOT_PASSWORD=...`.

</details>

## Verify

```bash
kubectl get endpointslices -n shop -l kubernetes.io/service-name=web-service   # one endpoint
kubectl run -it --rm --restart=Never t --image=busybox -n shop -- wget -qO- http://web-service:8080   # nginx page
kubectl get pods -n shop                                                        # all Running, db RESTARTS not growing
kubectl get events -n shop --sort-by='.lastTimestamp' | tail                   # no new Warning lines
```

When done, click **CHECK**.
