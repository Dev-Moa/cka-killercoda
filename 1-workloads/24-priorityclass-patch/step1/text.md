# Create the PriorityClass and patch the Deployment

A PriorityClass tells the scheduler how important a pod is: a pod with
a higher priority value gets scheduled before lower-priority pods. The
exam often asks you to update a live resource using only `kubectl` —
`kubectl patch` changes the object in place, faster than editing a
manifest file. In this exercise you create a high-priority Deployment,
then patch its pod template to add the priority class.

Namespace `exercise-24` is ready for you.

1. Create a PriorityClass named `critical-priority` with value
   `999999` and description `Critical workload`.
2. Create a Deployment named `critical-app` in namespace
   `exercise-24` with 1 replica and image `busybox:1.36`. Do NOT set
   `priorityClassName` yet. Note: busybox exits immediately, so give
   the container a command like `["sleep","3600"]` so the pod stays
   Running.
3. Use `kubectl patch` to add `priorityClassName: critical-priority`
   to the Deployment's pod template
   (`spec.template.spec.priorityClassName`).
4. Verify the running pod now carries the priority class.
5. Create a second, lower-priority Deployment in the same namespace
   (any name, any image that stays alive) with no
   `priorityClassName`, to compare.
6. Confirm the PriorityClass value is `999999`.

When done, click **CHECK**.
