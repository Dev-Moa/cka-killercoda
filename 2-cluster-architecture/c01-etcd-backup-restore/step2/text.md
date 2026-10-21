5. Restore the snapshot into a new data directory
   `/var/lib/etcd-from-backup`.
6. Point the etcd static pod at the new data directory and wait for
   etcd and the API server to come back.
7. Verify the deployment `after-snapshot` is gone.

## Verify

```bash
kubectl get pods -n kube-system | grep etcd                                 # after task 6: Running again
kubectl get deploy after-snapshot                                           # after task 7: NotFound
```

When done, click **CHECK**.
