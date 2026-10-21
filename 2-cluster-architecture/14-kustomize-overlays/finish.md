## What tripped me up

> All paths in `kustomization.yaml` are relative to the file's location. I used an absolute path (`/home/user/kustomize-lab/base/`) and got a cryptic error about paths not being within the root. Keep everything relative: `../../base` from the overlay directory. This bit me twice during practice.
>
> Also: I forgot the `resources:` field in the overlay kustomization.yaml. Without pointing to the base, Kustomize has nothing to patch. It just silently produces empty output. I applied it and wondered why nothing was created. Run `kubectl kustomize <dir>/ | less` first to preview what you're about to apply — if it's empty, something's wrong with your kustomization.yaml.

<details>
<summary>Solution</summary>

```bash
mkdir -p kustomize-lab/base kustomize-lab/overlays/staging
```

base/deployment.yaml:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app
  template:
    metadata:
      labels:
        app: app
    spec:
      containers:
      - name: nginx
        image: nginx:1.27
        ports:
        - containerPort: 80
```

base/service.yaml:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: app-svc
spec:
  selector:
    app: app
  ports:
  - port: 80
    targetPort: 80
```

base/kustomization.yaml:
```yaml
resources:
- deployment.yaml
- service.yaml
```

overlays/staging/kustomization.yaml:
```yaml
resources:
- ../../base

namespace: exercise-14

commonLabels:
  env: staging

replicas:
- name: app
  count: 3
```

```bash
k create ns exercise-14
k apply -k kustomize-lab/overlays/staging/

# Verify
k get pods -n exercise-14
k get deploy app -n exercise-14 --show-labels
k get svc app-svc -n exercise-14
```

</details>
