# Exercise 06 — Deployment Rolling Update and Rollback

Create a Deployment, perform a rolling update, check rollout history, and rollback.

## Tasks

1. Create a namespace called `exercise-06`
2. Create a Deployment named `webapp` with:
   - 3 replicas
   - Image: `nginx:1.28`
   - Strategy: RollingUpdate with maxSurge=1, maxUnavailable=0
   - Record the change cause
3. Verify all 3 replicas are running
4. Update the image to `nginx:1.29` and record the change
5. Watch the rollout status
6. Check rollout history — you should see 2 revisions
7. Rollback to the previous version (nginx:1.28)
8. Verify the rollback worked by checking the image

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- `k create deployment webapp --image=nginx:1.28 --replicas=3`
- `k set image deployment/webapp` to update
- `k rollout status`, `k rollout history`, `k rollout undo`
- Annotate with `kubernetes.io/change-cause` to track changes in rollout history

</details>

## Verify

```bash
# After initial deploy
k get deploy webapp -n exercise-06
k get rs -n exercise-06

# After rollback — image should be nginx:1.28
k get deploy webapp -n exercise-06 -o jsonpath='{.spec.template.spec.containers[0].image}'
```

When done, click **CHECK**.
