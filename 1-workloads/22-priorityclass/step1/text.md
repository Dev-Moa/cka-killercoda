# Exercise 22 — PriorityClass

---

## Context

PriorityClass defines the relative importance of pods. When nodes have limited resources, the scheduler prioritizes high-priority pods first. If a high-priority pod can't fit on any node, the scheduler can evict lower-priority pods to make room (preemption).

On the exam, you'll create PriorityClasses and assign them to pods. You need to know the difference between priority values, how preemption works, and how to debug which pods get scheduled when resources are tight.

---

## Tasks

1. Create a PriorityClass named `high-priority` with value 1000 and preemptionPolicy set to `PreemptLowerPriority`.

2. Create a PriorityClass named `low-priority` with value 10 and preemptionPolicy set to `Never`.

3. Create a Pod named `critical-app` using `nginx:1.28` and assign it to the `high-priority` class.

4. Create a Pod named `background-job` using `busybox:1.37` to run `sleep 3600` and assign it to the `low-priority` class.

5. Verify both pods are running. Check their priority values with `kubectl get pod -o json` and filter for `priority` and `priorityClassName`.

6. If possible, drain a node to trigger preemption and observe which pod gets evicted.

---

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- **Priority values**: Higher number = higher priority. System pods use 2000000000 (reserved by Kubernetes). Use 1-1000 for application priorities to stay safe.
- **preemptionPolicy: PreemptLowerPriority**: Allow this priority class to evict lower-priority pods if resources are scarce.
- **preemptionPolicy: Never**: This priority class will not evict or be evicted, even if it can't fit. It'll just wait.
- Default priority is 0. Pods without an explicit PriorityClass use priority 0.
- You must create a PriorityClass with `kind: PriorityClass` (not a built-in). PriorityClasses are cluster-wide, not namespaced.
- Preemption only happens when the scheduler can't fit a pod and has eviction candidates. It's not automatic.

</details>

---

## Verify

```bash
# Check PriorityClasses exist
k get priorityclass -o wide

# Check pod priority
k get pod -o wide

# Fast priority check (all pods in one table)
k get pod -o custom-columns=NAME:.metadata.name,CLASS:.spec.priorityClassName,PRIORITY:.spec.priority

# Single pod checks (exam-safe, no jq needed)
k get pod critical-app -o jsonpath='{.spec.priorityClassName}{" "}{.spec.priority}{"\n"}'
k get pod background-job -o jsonpath='{.spec.priorityClassName}{" "}{.spec.priority}{"\n"}'

# Check pod scheduling
k describe pod critical-app
k describe pod background-job

# Monitor preemption (if draining a node)
k get events --sort-by='.lastTimestamp'
```


When done, click **CHECK**.
