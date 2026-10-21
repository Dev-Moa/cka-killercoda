# Exercise C01 — etcd Backup and Restore

Take a snapshot of etcd, change the cluster, then restore the snapshot
so the change disappears. This is the task the repo's author says took
a week to get reliable. Needs a kubeadm cluster where etcd runs as a
static pod on the control plane node (not kind, not Docker Desktop).

## Tasks

Run everything on the control plane node.

1. Find the etcd pod and read from its manifest: the endpoint it
   listens on, the CA certificate, the server certificate and key, and
   the data directory.
2. Save a snapshot of etcd to `/opt/snapshot-pre-boot.db`.
3. Check the snapshot status (it must show a size and a hash).
4. Create a deployment named `after-snapshot` with image `nginx`. It
   must NOT exist after the restore.

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- The flags you need are all in
  `/etc/kubernetes/manifests/etcd.yaml`: `--listen-client-urls`,
  `--trusted-ca-file`, `--cert-file`, `--key-file`, `--data-dir`.
  Or `kubectl describe pod etcd-<node> -n kube-system`.
- Every `etcdctl` command needs `--endpoints`, `--cacert`, `--cert`,
  `--key`. Without them it fails with a TLS error.
- `restore` does not talk to the running etcd. It only writes a new
  data directory. The cluster only changes when the etcd pod uses it.
- In the etcd manifest the data directory appears twice: the
  `--data-dir` argument and the `hostPath` of the volume mounted at
  `/var/lib/etcd`. Change the hostPath to the new directory. The
  kubelet restarts the static pod on save.
- The docs page "Operating etcd clusters for Kubernetes" has both
  commands with all flags. Ctrl+F "snapshot save".

</details>

## Verify

```bash
ETCDCTL_API=3 etcdctl snapshot status /opt/snapshot-pre-boot.db -w table   # after task 3: hash, revision, size
kubectl get deploy after-snapshot                                           # after task 4: exists
```

When done, click **CHECK**.
