# Exercise C04 — KubeConfig

Every kubectl call needs a server address, your client cert and key,
and the CA cert. They live in a kubeconfig file (`~/.kube/config` by
default) as three lists: clusters, users, contexts. The exam hands you
a file and asks you to use it, switch contexts, or fix it.

## Tasks

Work on the control plane node (or wherever kubectl works).

1. Read the current config: `kubectl config view`. Count its clusters,
   users and contexts, and note the `current-context`.
2. Copy `/etc/kubernetes/admin.conf` to `/tmp/my-kube-config` and use
   ONLY that file: `kubectl --kubeconfig /tmp/my-kube-config get nodes`.
3. Set the default namespace of its context to `kube-system`, then
   prove it: `kubectl --kubeconfig /tmp/my-kube-config get pods` must
   list kube-system pods with no `-n`.
4. Break the file: change the `server:` port from `6443` to `6442`.
   Prove kubectl now fails with a connection error, then fix the port
   and prove it works again.
5. Make the custom file the default for your shell:
   `export KUBECONFIG=/tmp/my-kube-config`. Verify `kubectl get nodes`
   uses it, then `unset KUBECONFIG`.

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- `kubectl config view --kubeconfig=<file>`, `get-contexts`,
  `current-context`, `use-context`.
- Default namespace:
  `kubectl --kubeconfig /tmp/my-kube-config config set-context --current --namespace=kube-system`
  (writes into the file, not the cluster).
- A broken file is almost always the `server:` host/port (6443) or a
  cert path. Compare against `/etc/kubernetes/pki` — the kubeadm admin
  file is the reference for correct values.
- `kubectl config view` shows cert data as REDACTED; that is normal.

</details>

## Verify

```bash
kubectl --kubeconfig /tmp/my-kube-config get nodes                 # works
kubectl --kubeconfig /tmp/my-kube-config get pods                  # kube-system pods, no -n needed
kubectl --kubeconfig /tmp/my-kube-config config get-contexts       # namespace kube-system on the context
kubectl config current-context                                     # original context untouched
```

When done, click **CHECK**.
