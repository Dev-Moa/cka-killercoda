# ConfigMap & Secret - done

The exam facts from this exercise:

- `kubectl create configmap app-config --from-literal=APP_MODE=production` makes a ConfigMap in one command — no YAML needed.
- Secrets work the same way: `kubectl create secret generic db-creds --from-literal=DB_USER=admin`.
- `envFrom` loads ALL keys from a ConfigMap/Secret as env vars. `env.valueFrom.configMapKeyRef` loads ONE key. Getting them backwards gives wrong variable names, not an error.
- Mount a whole ConfigMap as files with a `volumes` entry plus `volumeMounts` at `/etc/config` — every key becomes a file.
- Pod stuck in `CreateContainerConfigError`? Check `kubectl describe pod` events first — the event names the missing ConfigMap or Secret (a typo like `app-conf` is the usual cause).
- Verify inside the pod: `kubectl exec app -n exercise-03 -- env` and `kubectl exec app -n exercise-03 -- ls /etc/config/`.

The exercise is based on the ConfigMap and Secret notes in
`notes/4-application-lifecycle-management/38` and `39`, and exercise 03
in `cka-prep/exercises/1-workloads/`.
