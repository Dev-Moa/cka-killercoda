# PriorityClass patch - done

The exam facts from this exercise:

- Higher priority value = higher priority = scheduled first.
- `kubectl patch` is the answer for "update this Deployment using
  only kubectl" — faster than editing a YAML file.
- Patch the pod template, NOT the Deployment spec:
  `-p '{"spec":{"template":{"spec":{"priorityClassName":"critical-priority"}}}}'`.
- Create the PriorityClass first, then patch the Deployment to use it.
- User priority values are usually 0-1000000 — use `999999` for
  "high priority" so the pod wins under resource pressure.
- Verify with
  `kubectl get deploy critical-app -o jsonpath='{.spec.template.spec.priorityClassName}'`.

The exercise is based on exercise 24 in
`cka-prep/exercises/1-workloads/`.
