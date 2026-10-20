# Build and scale the StatefulSet

Work in the `default` namespace.

1. Create a headless Service named `mysql` in `default`: `clusterIP: None`,
   port `3306`, selector `app=mysql`.

2. Create a StatefulSet named `mysql` in `default` with `3` replicas,
   image `nginx:1.28`, `serviceName: mysql`, and a `volumeClaimTemplates`
   entry named `data` requesting `1Gi` storage. Pods must have the label
   `app=mysql`.

3. Watch the pods start. They come up in order: `mysql-0`, then `mysql-1`,
   then `mysql-2`:

   `kubectl get pods -w`{{exec}}

   (press Ctrl+C to stop watching)

4. Delete pod `mysql-1` and watch it come back with the same name:

   `kubectl delete pod mysql-1`{{exec}}

5. Scale the StatefulSet up to `4` replicas, then down to `2`:

   `kubectl scale statefulset mysql --replicas=4`{{exec}}

   `kubectl scale statefulset mysql --replicas=2`{{exec}}

6. Finish with: StatefulSet `mysql` at 2 replicas, pods `mysql-0` and
   `mysql-1` Running, and the headless Service present.

Use these manifests as a start:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql
  labels:
    app: mysql
spec:
  ports:
  - port: 3306
    name: mysql
  clusterIP: None
  selector:
    app: mysql
```{{copy}}

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: nginx
        image: nginx:1.28
        ports:
        - containerPort: 3306
          name: mysql
        volumeMounts:
        - name: data
          mountPath: /data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
```{{copy}}

When done, click CHECK.
