# Exercise W04 — Commands and Arguments

The image decides what a container runs (ENTRYPOINT) and its default
parameters (CMD). The pod definition overrides both without a new
image: `command` replaces ENTRYPOINT, `args` replaces CMD. The exam
phrases it as "make this busybox pod sleep 3600".

## Tasks

Work in the `default` namespace.

1. Create a pod named `arg-demo` with image `busybox`. Use only
   `args` so the container runs `sleep 3600` (busybox starts `sh`, so
   the args override its CMD). The pod must stay Running.
2. Create a pod named `cmd-demo` with image `busybox`. Use `command`
   and `args` so it runs `sleep 120` — the command replaces the
   image's default program entirely.
3. Check what each pod actually runs:
   `kubectl get pod cmd-demo -o yaml | grep -A3 -E 'command|args'`.
4. Make `cmd-demo` sleep `3600` instead of 120.

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- `command` ↔ Dockerfile ENTRYPOINT, `args` ↔ CMD. Both are arrays.
- Generate the pod skeleton first, then add the fields:
  `kubectl run cmd-demo --image=busybox --dry-run=client -o yaml`.
- A running pod's `command`/`args` are immutable — task 4 means delete
  and recreate (`kubectl replace --force` or delete + apply).

</details>

## Verify

```bash
kubectl get pods arg-demo cmd-demo                                  # both Running
kubectl get pod cmd-demo -o jsonpath='{.spec.containers[0].command}{"\n"}{.spec.containers[0].args}{"\n"}'   # ["sleep"] then ["3600"]
```

When done, click **CHECK**.
