<details>
<summary>Solution</summary>

```yaml
# arg-demo: args only — busybox has no ENTRYPOINT, so the args are the
# whole command
apiVersion: v1
kind: Pod
metadata:
  name: arg-demo
spec:
  containers:
  - name: busybox
    image: busybox
    args: ["sleep", "3600"]
```

```yaml
# cmd-demo: command replaces the image's default program
apiVersion: v1
kind: Pod
metadata:
  name: cmd-demo
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sleep"]
    args: ["3600"]
```

**Key insight:** `command` replaces ENTRYPOINT entirely; `args` only
overrides the default CMD parameters. "Sleep 3600" on a busybox pod is
always `command: ["sleep"]` + `args: ["3600"]` — the exam's favourite
one-liner.

</details>
