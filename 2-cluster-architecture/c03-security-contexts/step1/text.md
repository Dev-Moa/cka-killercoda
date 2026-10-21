# Exercise C03 — Security Contexts

A security context sets privilege settings — the user ID and Linux
capabilities — on a pod or a container. Container level wins over pod
level. The exam phrases it as "run the container as user 1000" or "add
the MAC_ADMIN capability".

## Tasks

Work in the `default` namespace.

1. Create a pod named `sec-demo` with image `ubuntu` that runs
   `sleep 3600`. Give the container a `securityContext` so it runs as
   user `1000`, and add the `MAC_ADMIN` capability.
2. Prove the process runs as 1000: `kubectl exec sec-demo -- id -u`
   must print `1000`.
3. Create a pod named `sec-pod` with TWO containers (`ubuntu`, each
   `sleep 3600`). Put `runAsUser: 1000` at pod level instead — no
   per-container block. Verify BOTH containers run as 1000.
4. Check the applied settings:
   `kubectl get pod sec-demo -o jsonpath='{.spec.containers[0].securityContext}'`.

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- Container level: `securityContext` inside the container, next to
  `image:`. Pod level: the same block next to `containers:` under
  `spec`, and every container gets it.
- If pod and container both set the same field, the container wins.
- `MAC_ADMIN` is the lecture's example capability; the `add:` list
  takes any Linux capability.

</details>

## Verify

```bash
kubectl exec sec-demo -- id -u                                              # 1000
kubectl get pod sec-demo -o jsonpath='{.spec.containers[0].securityContext.capabilities.add}{"\n"}'   # [MAC_ADMIN]
kubectl exec sec-pod -c c1 -- id -u                                         # 1000
kubectl exec sec-pod -c c2 -- id -u                                         # 1000
```

When done, click **CHECK**.
