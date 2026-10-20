# Resource requests tuning - done

The exam facts from this exercise:

- Requests are a promise the scheduler must keep: a pod that asks for
  more than a node can give stays Pending, even if it uses almost
  nothing at runtime.
- When pods stay Pending, read the pod Events first to find which
  resource is insufficient.
- Do not trust a fixed rule like "reserve 10%": check the real numbers
  with `kubectl describe node <node>` — Allocatable vs. what is already
  allocated. Exam nodes differ in size and system pods.
- Fix the Deployment, not the pods: lower
  `spec.template.spec.containers[].resources.requests` with
  `kubectl edit` or `kubectl patch`; the ReplicaSet then replaces the
  pods.
- Core commands: `kubectl get pods -n exercise-23` (Pending?),
  `kubectl describe pod <pod> -n exercise-23` (Events),
  `kubectl describe node <node>` (Allocatable vs. Allocated).

The exercise is based on exercise 23 in
`cka-prep/exercises/1-workloads/` (CK-X question 8).
