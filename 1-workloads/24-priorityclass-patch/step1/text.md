# Create the PriorityClass and patch the Deployment

Namespace `exercise-24` is ready for you.

1. Create a PriorityClass named `critical-priority` with value
   `999999` and description `Critical workload`.
2. Create a Deployment named `critical-app` in namespace
   `exercise-24` with 1 replica and image `busybox:1.36`. Do NOT set
   `priorityClassName` yet. Busybox exits immediately, so give the
   container a command like `["sleep","3600"]` so the pod stays
   Running.
3. Use `kubectl patch` to add `priorityClassName: critical-priority`
   to the Deployment's pod template
   (`spec.template.spec.priorityClassName`).
4. Verify the running pod now carries the priority class:

   `kubectl get pods -n exercise-24 -o jsonpath='{.items[0].spec.priorityClassName}'`{{exec}}

5. Create a second, lower-priority Deployment in the same namespace
   (any name, any image that stays alive) with no
   `priorityClassName`, to compare.
6. Confirm the PriorityClass value is `999999`:

   `kubectl get priorityclass critical-priority -o jsonpath='{.value}'`{{exec}}

Use this patch command:

```bash
kubectl patch deployment critical-app -n exercise-24 \
  -p '{"spec":{"template":{"spec":{"priorityClassName":"critical-priority"}}}}'
```{{copy}}

When done, click **CHECK**.
