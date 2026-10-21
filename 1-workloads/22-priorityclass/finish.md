## What tripped me up

I thought higher priority pods always run first. They do — but only when the scheduler evaluates new pods. If low-priority pods are already running and using resources, the high-priority pod still has to wait unless preemption kicks in.

I also confused priority (user-defined) with QoS (Quality of Service: Guaranteed, Burstable, BestEffort), which is automatic based on resource limits. They're different and work together.

Creating a Pod with a nonexistent PriorityClass doesn't fail — it just fails to schedule (pending forever). No error message. You have to check the events: `kubectl describe pod <name>`.

---

<details>
<summary><b>Solution</b></summary>

**Step 1: Create PriorityClasses**

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000
preemptionPolicy: PreemptLowerPriority
globalDefault: false
description: "High priority for critical applications"
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 10
preemptionPolicy: Never
globalDefault: false
description: "Low priority for background jobs"
```

```bash
k apply -f priorityclasses.yaml
```

Verify:
```bash
k get priorityclass
# NAME              VALUE        GLOBAL-DEFAULT   AGE
# high-priority     1000         false            5s
# low-priority      10           false            5s
```

**Step 2: Create Pods with PriorityClasses**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: critical-app
spec:
  priorityClassName: high-priority
  containers:
  - name: app
    image: nginx:1.28
---
apiVersion: v1
kind: Pod
metadata:
  name: background-job
spec:
  priorityClassName: low-priority
  containers:
  - name: worker
    image: busybox:1.37
    command: ["sleep", "3600"]
```

```bash
k apply -f pods.yaml
```

**Step 3: Verify Priority**

```bash
k get pod -o wide
k get pod critical-app -o json | jq '.spec.priorityClassName'
# "high-priority"

k get pod critical-app -o json | jq '.spec.priority'
# 1000

k get pod background-job -o json | jq '.spec.priority'
# 10
```

**Step 4: Trigger Preemption (optional)**

If you have a multi-node cluster, drain a node:

```bash
k drain <node> --ignore-daemonsets --delete-emptydir-data
```

Monitor with:
```bash
k get events --sort-by='.lastTimestamp'
```

The `background-job` pod should be evicted (assuming resources force it), and `critical-app` should remain running because it has higher priority.

**Step 5: Cleanup**

```bash
k delete pod critical-app background-job
k delete priorityclass high-priority low-priority
```

</details>
