# Exercise 01 — Pod Basics

Create a pod with specific resource requests, labels, and verify it's running.

## Tasks

1. Create a namespace called `exercise-01`
2. Create a pod named `web` in namespace `exercise-01` with these specs:
   - Image: `nginx:1.27`
   - Labels: `app=web`, `tier=frontend`
   - Resource requests: 64Mi memory, 100m CPU
   - Resource limits: 128Mi memory, 250m CPU
3. Verify the pod is running and has the correct labels
4. Get the pod's IP address using `-o wide`
5. Add a new label `version=v1` to the running pod
6. Remove the `tier` label from the pod

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- Use `k run` to generate the YAML, then edit it to add resources
- `k label pod` to add labels, `k label pod <name> <label>-` to remove them
- Resource fields go under `spec.containers[].resources`

</details>

## Verify

```bash
# Pod should be Running
k get pod web -n exercise-01

# Should show app=web,version=v1
k get pod web -n exercise-01 --show-labels

# Should show IP
k get pod web -n exercise-01 -o wide
```

When done, click **CHECK**.
