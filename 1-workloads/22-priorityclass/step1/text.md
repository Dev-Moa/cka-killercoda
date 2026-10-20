# Create the PriorityClasses and pods

Work in the `default` namespace. PriorityClasses are cluster-wide, so
they do not go in a namespace.

1. Create a PriorityClass named `high-priority` with value `1000` and
   preemptionPolicy `PreemptLowerPriority`.

2. Create a PriorityClass named `low-priority` with value `10` and
   preemptionPolicy `Never`.

3. Create a Pod named `critical-app` in `default` using image
   `nginx:1.28`, assigned to the `high-priority` PriorityClass.

4. Create a Pod named `background-job` in `default` using image
   `busybox:1.37` with the command `sleep 3600`, assigned to the
   `low-priority` PriorityClass.

5. Verify both pods are Running and check their priority values
   (`spec.priority` and `spec.priorityClassName`):

   `kubectl get pods -o custom-columns=NAME:.metadata.name,CLASS:.spec.priorityClassName,PRIORITY:.spec.priority`{{exec}}

Use this manifest for the PriorityClasses:

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
```{{copy}}

And this manifest for the pods:

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
```{{copy}}

When done, click **CHECK**.
