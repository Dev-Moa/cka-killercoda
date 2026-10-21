# Exercise 03 — ConfigMap and Secret

Create ConfigMaps and Secrets, then inject them into a pod as environment variables and mounted files.

## Tasks

1. Create a namespace called `exercise-03`
2. Create a ConfigMap named `app-config` with:
   - Key `APP_MODE` = `production`
   - Key `LOG_LEVEL` = `debug`
3. Create a Secret named `db-creds` with:
   - Key `DB_USER` = `admin`
   - Key `DB_PASS` = `s3cretP@ss`
4. Create a pod named `app` that:
   - Uses image `busybox:1.36`, command `sleep 3600`
   - Loads `APP_MODE` and `LOG_LEVEL` from the ConfigMap as env vars
   - Loads `DB_USER` and `DB_PASS` from the Secret as env vars
   - Mounts the entire ConfigMap as files at `/etc/config/`
5. Verify the env vars are set inside the pod
6. Verify the mounted files exist at `/etc/config/`

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- `k create configmap app-config --from-literal=APP_MODE=production --from-literal=LOG_LEVEL=debug`
- `k create secret generic db-creds --from-literal=DB_USER=admin --from-literal=DB_PASS=s3cretP@ss`
- Use `envFrom` to load all keys from a ConfigMap or Secret
- Use `volumes` + `volumeMounts` to mount ConfigMap as files

</details>

## Verify

```bash
# Check env vars
k exec app -n exercise-03 -- env | grep -E "APP_MODE|LOG_LEVEL|DB_USER|DB_PASS"

# Check mounted files
k exec app -n exercise-03 -- ls /etc/config/
k exec app -n exercise-03 -- cat /etc/config/APP_MODE
```

When done, click **CHECK**.
