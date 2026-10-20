# Create, update, and roll back the deployment

A Deployment manages a set of identical pod replicas. A rolling update
replaces the pods gradually — a few at a time — so the application stays
available while the new image is rolled out. Every update is saved as a
revision in the rollout history, and you can go back to a previous
revision with a rollback. The exam trap: the old `--record` flag is
deprecated — record each change cause by annotating the Deployment with
`kubernetes.io/change-cause` instead.

1. Create a namespace called `exercise-06`.

2. Create a Deployment named `webapp` in the `exercise-06` namespace with:

   - 3 replicas
   - Image: `nginx:1.28`
   - Strategy: RollingUpdate with `maxSurge=1`, `maxUnavailable=0`
   - Record the change cause by annotating the Deployment with
     `kubernetes.io/change-cause`

3. Verify all 3 replicas are running.

4. Update the image to `nginx:1.29` and record the change (annotate
   again with `--overwrite`).

5. Watch the rollout status.

6. Check the rollout history.

7. Roll back to the previous version (`nginx:1.28`).

8. Verify the rollback worked by checking the image.

When done, click **CHECK**.
