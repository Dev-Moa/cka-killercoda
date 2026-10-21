# Exercise 14 — Kustomize: Base and Overlay

Build a base deployment and apply an overlay that changes the namespace and replica count. Kustomize is built into kubectl and is now part of the CKA skill set.

## Tasks

1. Create a directory structure:
   ```
   kustomize-lab/
     base/
       deployment.yaml
       service.yaml
       kustomization.yaml
     overlays/
       staging/
         kustomization.yaml
   ```
2. In the base:
   - A Deployment named `app` with image `nginx:1.27` and 1 replica
   - A ClusterIP Service named `app-svc` on port 80
   - A `kustomization.yaml` listing both resources
3. In the staging overlay:
   - Set namespace to `exercise-14`
   - Patch replicas to 3
   - Add a common label `env: staging`
4. Create namespace `exercise-14`
5. Apply the staging overlay with `kubectl apply -k`
6. Verify 3 pods are running in namespace `exercise-14` with label `env=staging`

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- `kubectl apply -k <overlay-dir>/`
- `kubectl kustomize <overlay-dir>/` to preview the output without applying
- Overlay `kustomization.yaml` references the base with `resources: [../../base]`
- Use `replicas` field in kustomization.yaml to patch replica count

</details>

## Verify

```bash
# 3 pods running
k get pods -n exercise-14

# Label applied
k get deploy app -n exercise-14 --show-labels | grep staging

# Service created
k get svc app-svc -n exercise-14
```

When done, click **CHECK**.
