# Jobs & CronJobs

Work in the `default` namespace.

1. Create a Job named `cleanup-job` that runs image `busybox:1.37` with
   the command `echo "Cleanup complete"`. It must complete successfully
   3 times (`completions: 3`), one pod at a time (`parallelism: 1`).

2. Verify the Job reaches `3/3` completions and check the pod logs —
   each pod prints `Cleanup complete`:

   `kubectl get job cleanup-job`{{exec}}

   `kubectl logs job/cleanup-job --all-containers=true`{{exec}}

3. Create a CronJob named `hourly-backup` that runs every hour
   (schedule `0 * * * *`). Use the same `busybox:1.37` image and keep 3
   successful job histories (`successfulJobsHistoryLimit: 3`).

4. List the CronJobs and note the next scheduled time:

   `kubectl get cronjob hourly-backup`{{exec}}

5. Manually trigger the CronJob once: create a Job from it with
   `kubectl create job <name> --from=cronjob/hourly-backup`.

6. Verify the manual Job ran and its logs show the output:

   `kubectl get jobs`{{exec}}

   `kubectl logs job/<your-job-name>`{{exec}}

Use these manifests:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: cleanup-job
spec:
  completions: 3
  parallelism: 1
  backoffLimit: 3
  template:
    spec:
      containers:
      - name: cleanup
        image: busybox:1.37
        command: ["echo", "Cleanup complete"]
      restartPolicy: Never
```{{copy}}

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hourly-backup
spec:
  schedule: "0 * * * *"
  successfulJobsHistoryLimit: 3
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: busybox:1.37
            command: ["echo", "Cleanup complete"]
          restartPolicy: OnFailure
```{{copy}}

When done, click **CHECK**.
