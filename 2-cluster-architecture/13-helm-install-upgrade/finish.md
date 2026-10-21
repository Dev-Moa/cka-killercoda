## What tripped me up

> `helm install` failed with "namespace exercise-13 not found" because I forgot `--create-namespace`. Unlike `kubectl`, Helm doesn't create the namespace for you by default. I wasted 2 minutes creating the namespace manually, then realized `--create-namespace` does it in one shot. Use it every time.
>
> When rolling back, I ran `helm rollback web` without the revision number. It defaults to the previous revision, which worked in this case. But on the exam, if there are 4+ revisions and you need a specific one, you have to check `helm history` first and specify the revision number explicitly. I got lucky in practice but almost got burned on a more complex scenario.

<details>
<summary>Solution</summary>

```bash
# Add repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Install
helm install web bitnami/nginx -n exercise-13 --create-namespace --set replicaCount=2

# Verify
helm list -n exercise-13
k get pods -n exercise-13

# Upgrade
helm upgrade web bitnami/nginx -n exercise-13 --set replicaCount=3

# Check history
helm history web -n exercise-13

# Rollback
helm rollback web 1 -n exercise-13

# Verify rollback
k get deploy -n exercise-13 -o jsonpath='{.items[0].spec.replicas}'
helm history web -n exercise-13
```

</details>
