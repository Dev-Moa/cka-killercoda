# Exercise 24 — PriorityClass and Patch Operations

Create a high-priority pod that gets scheduled before lower-priority pods. Practice using `kubectl patch` to modify existing resources without editing manifests.

## Tasks

1. Create a namespace called `exercise-24`
2. Create a PriorityClass with:
   - Name: `high-priority`
   - Value: `999999` (one less than 1000000 — max priority)
   - Description: "Critical workload"
3. Create a Deployment named `critical-app`:
   - 1 replica initially
   - Image: `busybox:1.36`
   - Do NOT specify priorityClassName yet
4. Use `kubectl patch` to add `priorityClassName: high-priority` to the Deployment
5. Verify the pod has the priority class assigned
6. Create a second lower-priority Deployment to compare
7. Verify scheduling order respects priority

## Key Learning

- PriorityClass affects pod scheduling order
- Higher value = higher priority = schedules first
- `kubectl patch` is faster than editing files in exam
- Exam often asks: "Update this Deployment using only kubectl" → patch is the answer

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- `k create priorityclass high-priority --value=999999`
- `k patch deployment <name> -p '{"spec":{"template":{"spec":{"priorityClassName":"high-priority"}}}}'`
- Verify patch worked: `k get deploy <name> -o jsonpath='{.spec.template.spec.priorityClassName}'`
- Check pod has priority: `k get pod <pod> -o jsonpath='{.spec.priorityClassName}'`

</details>

## Verify

```bash
# PriorityClass exists
k get priorityclass high-priority

# Deployment has correctValue
k get deploy critical-app -n exercise-24 -o jsonpath='{.spec.template.spec.priorityClassName}'

# Pod has the priority class
k get pod -n exercise-24 -o jsonpath='{.items[0].spec.priorityClassName}'

# Check priority value
k describe priorityclass high-priority
```

When done, click **CHECK**.
