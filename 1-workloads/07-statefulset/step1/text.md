StatefulSets are for applications that need stable, predictable pod
names, ordered pod startup and shutdown, and persistent storage per pod
replica. Unlike a Deployment, where pod identity does not matter, a
StatefulSet keeps each pod's identity across restarts — for example, a
database cluster needs predictable names like `mysql-0`, `mysql-1`,
`mysql-2`. Each pod also gets a stable network identity through a
headless Service. This is a common CKA exam scenario: stateful workloads
such as databases.

Work in the `default` namespace.

1. Create a headless Service named `mysql` in `default`: `clusterIP: None`,
   port `3306`, selector `app=mysql`.

2. Create a StatefulSet named `mysql` in `default` with `3` replicas,
   image `nginx:1.28`, `serviceName: mysql`, and a `volumeClaimTemplates`
   entry named `data` requesting `1Gi` storage. Pods must have the label
   `app=mysql`.

3. Watch the pods start. They come up in order: `mysql-0`, then `mysql-1`,
   then `mysql-2`.

4. Delete pod `mysql-1` and watch it come back with the same name.

5. Scale the StatefulSet up to `4` replicas, then down to `2`.

6. Finish with: StatefulSet `mysql` at 2 replicas, pods `mysql-0` and
   `mysql-1` Running, and the headless Service present.

When done, click CHECK.
