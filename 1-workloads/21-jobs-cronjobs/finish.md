## What tripped me up

I expected completions=3 to mean "run 3 pods in parallel." It doesn't — it means "successfully complete 3 times total." With parallelism=1, those 3 runs are serial. If parallelism=3 and completions=3, all 3 run together.

I also forgot that CronJobs are in the `batch` API group, not `v1`. The YAML syntax is slightly different from Jobs.

When a Job fails, the pod isn't deleted unless the Job's `ttlSecondsAfterFinished` is set. Failed pods stick around for debugging, which is good. But if you're running a test Job, clean it up afterward or you'll have orphan pods.


<details>
<summary><b>Solution</b></summary>

**Step 1: Create the Job**

```bash
k create job cleanup-job \
  --image=busybox:1.37 \
  --command -- echo "Cleanup complete" 

# This creates a Job that runs once. For 3 completions:
k patch job cleanup-job --type json -p '[
  {"op": "replace", "path": "/spec/completions", "value": 3},
  {"op": "replace", "path": "/spec/parallelism", "value": 1}
]'
```

Or using a declarative YAML:

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
```

**Step 2: Verify Job runs**

```bash
k get job cleanup-job -w
# Watch until Completions shows 3/3

k get pod -l job-name=cleanup-job
# Should show 3 pods

k logs job/cleanup-job --all-containers=true
# Shows all pod logs from the Job
```

**Step 3: Create CronJob**

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hourly-backup
spec:
  schedule: "0 * * * *"  # Every hour at :00
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: busybox:1.37
            command: ["echo", "Backup at $(date)"]
          restartPolicy: OnFailure
```

```bash
k apply -f cronjob.yaml
```

**Step 4: List CronJobs**

```bash
k get cronjob hourly-backup
# SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
# 0 * * * *     False     0        <none>          20s
```

**Step 5: Manually trigger**

```bash
k create job hourly-backup-manual-1 --from=cronjob/hourly-backup
```

**Step 6: Verify manual Job**

```bash
k get job -l cronjob-name=hourly-backup
k logs job/hourly-backup-manual-1
```

</details>

## Resources

- [Kubernetes Batch Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/job/)
- [CronJobs](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)
- [Job backoff restart policy](https://kubernetes.io/docs/concepts/workloads/controllers/job/#pod-backoff-failure-policy)
