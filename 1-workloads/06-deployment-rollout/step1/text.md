# Create, update, and roll back the deployment

1. Create a namespace called `exercise-06`:

   `kubectl create namespace exercise-06`{{exec}}

   If it says the namespace already exists, that is fine — the setup
   created it for you. Move on.

2. Create a Deployment named `webapp` in the `exercise-06` namespace with:

   - 3 replicas
   - Image: `nginx:1.28`
   - Strategy: RollingUpdate with `maxSurge=1`, `maxUnavailable=0`
   - Record the change cause by annotating the Deployment with
     `kubernetes.io/change-cause`

   Generate the skeleton, then edit it:

   `kubectl create deployment webapp -n exercise-06 --image=nginx:1.28 --replicas=3 --dry-run=client -o yaml > deploy.yaml`{{exec}}

   Use this manifest — it already has the strategy:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: webapp
     namespace: exercise-06
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: webapp
     strategy:
       type: RollingUpdate
       rollingUpdate:
         maxSurge: 1
         maxUnavailable: 0
     template:
       metadata:
         labels:
           app: webapp
       spec:
         containers:
         - name: nginx
           image: nginx:1.28
   ```{{copy}}

   Apply it, then record the change cause:

   `kubectl apply -f deploy.yaml`{{exec}}

   `kubectl annotate deployment webapp -n exercise-06 kubernetes.io/change-cause="initial deploy nginx:1.28"`{{exec}}

3. Verify all 3 replicas are running:

   `kubectl get pods -n exercise-06`{{exec}}

4. Update the image to `nginx:1.29` and record the change (annotate
   again with `--overwrite`):

   `kubectl set image deployment/webapp nginx=nginx:1.29 -n exercise-06`{{exec}}

   `kubectl annotate deployment webapp -n exercise-06 kubernetes.io/change-cause="update to nginx:1.29" --overwrite`{{exec}}

5. Watch the rollout status:

   `kubectl rollout status deployment/webapp -n exercise-06`{{exec}}

6. Check the rollout history:

   `kubectl rollout history deployment/webapp -n exercise-06`{{exec}}

   You should see two revisions so far.

7. Roll back to the previous version (`nginx:1.28`):

   `kubectl rollout undo deployment/webapp -n exercise-06`{{exec}}

8. Verify the rollback worked by checking the image:

   `kubectl get deployment webapp -n exercise-06 -o jsonpath='{.spec.template.spec.containers[0].image}'`{{exec}}

   It should print `nginx:1.28`.

When done, click **CHECK**.
