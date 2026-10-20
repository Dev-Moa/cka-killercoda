# PriorityClass - done

The exam facts from this exercise:

- Higher number = higher priority. Pods without a PriorityClass use
  priority `0`.
- A high-priority pod only evicts lower pods when its
  `preemptionPolicy` is `PreemptLowerPriority`. `Never` means the pod
  waits instead.
- Priority is not QoS. QoS (Guaranteed/Burstable/BestEffort) comes
  automatically from requests and limits; priority is set by you.
- A pod that names a PriorityClass that does not exist never
  schedules — it stays Pending with no clear error. Check
  `kubectl describe pod <name>` events to see it.
- PriorityClasses are cluster-wide, so `kubectl get priorityclass`
  has no namespace argument.
- Set `priorityClassName` in the pod spec, then check the result with
  `kubectl get pods -o custom-columns=NAME:.metadata.name,CLASS:.spec.priorityClassName,PRIORITY:.spec.priority`.

The exercise is based on question 9 in `labs/ckx/exams/cka/101` and
exercise 22 in `cka-prep/exercises/1-workloads/`.
