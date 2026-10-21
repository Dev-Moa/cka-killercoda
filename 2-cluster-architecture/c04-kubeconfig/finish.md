<details>
<summary>Solution</summary>

```bash
# 2. copy the admin file
cp /etc/kubernetes/admin.conf /tmp/my-kube-config
kubectl --kubeconfig /tmp/my-kube-config get nodes

# 3. default namespace on the context
kubectl --kubeconfig /tmp/my-kube-config config set-context --current --namespace=kube-system
kubectl --kubeconfig /tmp/my-kube-config get pods    # kube-system pods

# 4. break and fix
sed -i 's/6443/6442/' /tmp/my-kube-config
kubectl --kubeconfig /tmp/my-kube-config get nodes   # connection refused / timeout
sed -i 's/6442/6443/' /tmp/my-kube-config
kubectl --kubeconfig /tmp/my-kube-config get nodes   # works again

# 5. default for the shell
export KUBECONFIG=/tmp/my-kube-config
kubectl get nodes
unset KUBECONFIG
```

**Key insight:** the kubeconfig is just the four flag values
(server, cert, key, CA) stored as named clusters/users/contexts. Fix
tasks are always about one of those values being wrong.

</details>
