# Create the ConfigMap, Secret and pod

A ConfigMap stores non-secret configuration as key-value pairs, and a
Secret stores sensitive data such as passwords. A pod can consume both
in two ways: as environment variables, or as files mounted into a
container. Creating these objects and injecting them into a pod is one
of the most common CKA tasks, so learn the flow end to end.

1. Create a namespace called `exercise-03`.

2. Create a ConfigMap named `app-config` in the `exercise-03` namespace
   with `APP_MODE=production` and `LOG_LEVEL=debug`.

3. Create a Secret named `db-creds` in the `exercise-03` namespace with
   `DB_USER=admin` and `DB_PASS=s3cretP@ss`.

4. Create a pod named `app` in the `exercise-03` namespace using
   `busybox:1.36` with the command `sleep 3600` that:

   - Loads all keys from the ConfigMap as environment variables
   - Loads all keys from the Secret as environment variables
   - Mounts the entire ConfigMap as files at `/etc/config/`

5. Verify the environment variables are set inside the pod.

6. Verify the mounted files exist at `/etc/config/`.

When done, click **CHECK**.
