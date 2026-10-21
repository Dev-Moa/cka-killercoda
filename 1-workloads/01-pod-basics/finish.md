## What tripped me up

> I created the pod in `default` the first time because I forgot `-n exercise-01` on the `k apply`. Zero points — the grader checks the exact namespace. Now I always run `kn <namespace>` before touching anything. Cost me 4 minutes the first time.
>
> Also: I kept trying to add resources directly in `k run`. You can't. You have to generate the YAML with `$do`, edit it, then apply. Don't fight the CLI — just redirect to a file.

<details>
<summary>Solution</summary>

```bash
# Create namespace
k create ns exercise-01

# Generate pod YAML
k run web -n exercise-01 --image=nginx:1.28 --labels=app=web,tier=frontend $do > pod.yaml
```

Edit `pod.yaml` to add resources:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web
  namespace: exercise-01
  labels:
    app: web
    tier: frontend
spec:
  containers:
  - name: web
    image: nginx:1.27
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "250m"
```

```bash
k apply -f pod.yaml

# Verify
k get pod web -n exercise-01 --show-labels
k get pod web -n exercise-01 -o wide

# Add label
k label pod web -n exercise-01 version=v1

# Remove label
k label pod web -n exercise-01 tier-
```

</details>
