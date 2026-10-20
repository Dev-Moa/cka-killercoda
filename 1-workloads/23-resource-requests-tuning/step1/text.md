# Resource requests tuning

A Deployment named `web` in namespace `exercise-23` has 3 replicas, but
every pod is Pending. The resource requests were set to impossible
values on purpose, so no node can fit them. Diagnose the failure, then
lower the requests so all 3 pods schedule and run. Keep the nginx image.

1. Describe one Pending pod in namespace `exercise-23` and read its
   Events — which resource is insufficient?

   `kubectl get pods -n exercise-23`{{exec}}

   `kubectl describe pod <pod-name> -n exercise-23`{{exec}}

2. Describe a node and compare its Allocatable capacity with what the
   pods request:

   `kubectl describe node <node-name>`{{exec}}

3. Update the Deployment `web` with realistic memory and CPU requests.
   Use `kubectl edit` or a patch — for example:

   ```bash
   kubectl patch deployment web -n exercise-23 \
     --type=json -p='[{"op":"replace",
     "path":"/spec/template/spec/containers/0/resources/requests",
     "value":{"memory":"128Mi","cpu":"100m"}}]'
   ```{{copy}}

4. Verify all 3 pods are Running:

   `kubectl get pods -n exercise-23`{{exec}}

Remember: a request is a promise the scheduler must keep — if a pod
asks for more than a node can give, it stays Pending no matter how
little it actually uses.

When all 3 pods are Running, click **CHECK**.
