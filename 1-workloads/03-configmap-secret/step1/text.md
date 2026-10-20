# Create the ConfigMap, Secret and pod

1. Create a namespace called `exercise-03`:

   The namespace is already created for you — nothing to do here.

2. Create a ConfigMap named `app-config` in the `exercise-03` namespace
   with `APP_MODE=production` and `LOG_LEVEL=debug`:

   `kubectl create configmap app-config -n exercise-03 --from-literal=APP_MODE=production --from-literal=LOG_LEVEL=debug`{{exec}}

3. Create a Secret named `db-creds` in the `exercise-03` namespace with
   `DB_USER=admin` and `DB_PASS=s3cretP@ss`:

   `kubectl create secret generic db-creds -n exercise-03 --from-literal=DB_USER=admin --from-literal=DB_PASS=s3cretP@ss`{{exec}}

4. Create a pod named `app` in the `exercise-03` namespace using
   `busybox:1.36` with the command `sleep 3600` that:
   - Loads all keys from the ConfigMap as environment variables
   - Loads all keys from the Secret as environment variables
   - Mounts the entire ConfigMap as files at `/etc/config/`

5. Verify the environment variables are set inside the pod:

   `kubectl exec app -n exercise-03 -- env`{{exec}}

6. Verify the mounted files exist at `/etc/config/`:

   `kubectl exec app -n exercise-03 -- ls /etc/config/`{{exec}}

Use this manifest for the pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app
  namespace: exercise-03
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sleep", "3600"]
    envFrom:
    - configMapRef:
        name: app-config
    - secretRef:
        name: db-creds
    volumeMounts:
    - name: config-vol
      mountPath: /etc/config
  volumes:
  - name: config-vol
    configMap:
      name: app-config
```{{copy}}

When done, click **CHECK**.
