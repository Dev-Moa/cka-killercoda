<details>
<summary>Solution</summary>

```yaml
# sec-demo: container-level
spec:
  containers:
  - name: ubuntu
    image: ubuntu
    command: ["sleep", "3600"]
    securityContext:
      runAsUser: 1000
      capabilities:
        add: ["MAC_ADMIN"]
```

```yaml
# sec-pod: pod-level, so every container gets it
spec:
  securityContext:
    runAsUser: 1000
  containers:
  - name: c1
    image: ubuntu
    command: ["sleep", "3600"]
  - name: c2
    image: ubuntu
    command: ["sleep", "3600"]
```

**Key insight:** same block, two places. One container → container
level; every container → move it up next to `containers:`. The
container-level value always wins.

</details>
