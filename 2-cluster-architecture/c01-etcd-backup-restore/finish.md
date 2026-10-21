<details>
<summary>Solution</summary>

```bash
# 1. read the flags from the manifest
cat /etc/kubernetes/manifests/etcd.yaml | grep -E "listen-client-urls|trusted-ca-file|cert-file|key-file|data-dir"
# --listen-client-urls=https://127.0.0.1:2379,...
# --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
# --cert-file=/etc/kubernetes/pki/etcd/server.crt
# --key-file=/etc/kubernetes/pki/etcd/server.key
# --data-dir=/var/lib/etcd

# 2. snapshot with endpoint and certs
ETCDCTL_API=3 etcdctl snapshot save /opt/snapshot-pre-boot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# 3. check it
ETCDCTL_API=3 etcdctl snapshot status /opt/snapshot-pre-boot.db -w table

# 4. a change that the restore must undo
kubectl create deployment after-snapshot --image=nginx

# 5. restore into a NEW directory (no endpoint needed, it only writes files)
ETCDCTL_API=3 etcdctl snapshot restore /opt/snapshot-pre-boot.db \
  --data-dir /var/lib/etcd-from-backup

# 6. point the static pod at the new directory
vi /etc/kubernetes/manifests/etcd.yaml
```

Change the hostPath volume:

```yaml
  volumes:
  - hostPath:
      path: /var/lib/etcd-from-backup    # was /var/lib/etcd
      type: DirectoryOrCreate
    name: etcd-data
```

```bash
# the kubelet restarts etcd; the API server flaps for a minute
watch kubectl get pods -n kube-system

# 7. the deployment made after the snapshot is gone
kubectl get deploy after-snapshot
```

**Key insight:** backup talks to the live etcd, so it needs the
endpoint and the three TLS files. Restore writes a fresh data directory
on disk and nothing else. The cluster changes only when etcd is
restarted on that directory, which on kubeadm means editing the static
pod manifest's hostPath.

</details>
