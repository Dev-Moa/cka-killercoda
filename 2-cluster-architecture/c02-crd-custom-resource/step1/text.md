# Exercise C02 — CRD and Custom Resource

The curriculum names "understand CRDs, install and configure
operators". The course has no written lecture for it, so this exercise
is built from the docs page you would open in the exam. The task shape
is always the same: create or inspect a CRD, then create an object of
the new kind and read it back.

## Tasks

1. List the CRDs already in the cluster. Pick one and find out its
   short name, scope (Namespaced or Cluster) and served versions.
2. Create a CRD for a kind `CronTab` in group `stable.example.com`,
   version `v1`, namespaced, plural `crontabs`, short name `ct`, with
   two string fields under `spec`: `cronSpec` and `image`.
3. Create a `CronTab` named `my-new-cron-object` in namespace
   `default` with `cronSpec: "* * * * */5"` and `image: my-awesome-cron-image`.
4. Read it back with the short name and with `kubectl explain`.

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- `kubectl get crd` lists them. `kubectl get crd <name> -o yaml` shows
  `spec.group`, `spec.names.shortNames`, `spec.scope`,
  `spec.versions[].served`.
- Never type a CRD. Open the docs page "Extend the Kubernetes API with
  CustomResourceDefinitions", Ctrl+F "crontabs.stable.example.com",
  copy the whole first example. It already has every field this
  exercise asks for.
- The CRD name must be `<plural>.<group>`.
- `kubectl api-resources | grep crontab` shows the new kind after the
  CRD is created.
- `kubectl explain crontab.spec` works once the schema is in.

</details>

## Verify

```bash
kubectl get crd crontabs.stable.example.com          # after task 2
kubectl api-resources | grep crontab                 # kind CronTab, short name ct
kubectl get ct                                       # after task 3: my-new-cron-object
kubectl get crontab my-new-cron-object -o yaml       # spec.cronSpec, spec.image
```

When done, click **CHECK**.
