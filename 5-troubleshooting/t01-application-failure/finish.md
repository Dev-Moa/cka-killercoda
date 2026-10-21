## Setup (do this without reading it twice)

```bash
kubectl create ns shop
kubectl run webapp --image=nginx -l name=webapp -n shop
kubectl expose pod webapp --port=8080 --target-port=80 --name=web-service -n shop
kubectl patch svc web-service -n shop -p '{"spec":{"selector":{"name":"webap"}}}'      # break 1: selector typo
kubectl run db --image=mysql -l name=db -n shop                                         # break 2: no MYSQL_ROOT_PASSWORD, crashes
kubectl run cache --image=redis:does-not-exist -n shop                                  # break 3: bad image tag
```

<details>
<summary>Solution</summary>

```bash
# 1. service with no endpoints: selector vs labels
kubectl describe svc web-service -n shop          # Selector: name=webap, Endpoints: <none>
kubectl get pods -n shop --show-labels            # webapp has name=webapp
kubectl edit svc web-service -n shop              # fix selector to name: webapp
kubectl get endpointslices -n shop                # endpoint appears
kubectl run -it --rm --restart=Never t --image=busybox -n shop -- wget -qO- http://web-service:8080

# 2. CrashLoopBackOff: read the previous container's log
kubectl get pods -n shop                          # db CrashLoopBackOff
kubectl logs db -n shop -p                        # "Database is uninitialized and password option is not specified"
kubectl delete pod db -n shop
kubectl run db --image=mysql -l name=db -n shop --env=MYSQL_ROOT_PASSWORD=pass
kubectl get pods -n shop -w                       # db Running, no restarts

# 3. ImagePullBackOff: events name the bad tag
kubectl describe pod cache -n shop | tail         # Failed to pull image "redis:does-not-exist"
kubectl set image pod/cache cache=redis -n shop
kubectl get pods -n shop

# 4. namespace events, time sorted
kubectl get events -n shop --sort-by='.lastTimestamp'
```

**Key insight:** the walk is always Service → endpoints → pod → logs.
Empty endpoints = selector or targetPort. CrashLoopBackOff = read the
previous container with `-p`. ImagePullBackOff = the image name or tag
in the events. Three alignments: selector vs labels, `port` →
`targetPort` → `containerPort`.

</details>
