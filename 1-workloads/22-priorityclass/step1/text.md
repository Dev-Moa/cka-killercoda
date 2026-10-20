# Create the PriorityClasses and pods

A PriorityClass defines how important a pod is. When a node is short
of resources, the scheduler runs high-priority pods first. A
high-priority pod can even evict a lower-priority pod to make room —
that is preemption. On the exam you create PriorityClasses, assign
them to pods, and check which pod the scheduler picks when resources
are tight.

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
   (`spec.priority` and `spec.priorityClassName`).

When done, click **CHECK**.
