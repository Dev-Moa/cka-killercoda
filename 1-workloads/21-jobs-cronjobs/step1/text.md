# Exercise 21 — Jobs and CronJobs

---

## Context

Jobs run one or more pods to completion. Unlike Deployments (which keep pods running indefinitely), Jobs don't restart failed pods by default — they just retry. CronJobs schedule Jobs to run on a schedule, like cron in Linux.

On the exam, you'll create both and understand backoff limits, completions, and restart policies. The questions are straightforward: create a job that runs a script to completion, handle failures, maybe schedule it for later.

---

## Tasks

1. Create a Job named `cleanup-job` that runs the image `busybox:1.37` with command `echo "Cleanup complete"`. Set it to run 3 times (completions=3) serially (parallelism=1).

2. Verify the Job runs to completion (status should show 3/3). Check the pod logs.

3. Create a CronJob named `hourly-backup` that runs `backup-script.sh` every hour. Use the same busybox image. Let it keep 3 successful job histories (successfulJobsHistoryLimit=3).

4. List CronJobs and check the next scheduled time.

5. Manually trigger the CronJob once (create a Job from it).

6. Verify the manual Job ran and logged output.

---

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- **completions=3**: The Job must run 3 times successfully before completion.
- **parallelism=1**: Run one pod at a time, serially.
- **backoffLimit=3**: Retry failed pods up to 3 times, then give up.
- **historyLimit**: Keep this many job history records. Default is 3 for success and 1 for failure.
- For CronJobs, use `spec.schedule` with standard cron syntax (e.g., `0 * * * *` = every hour).
- `kubectl get cronjob` shows the next scheduled time in the LAST SCHEDULE column.
- To manually trigger a CronJob: `kubectl create job <jobname> --from=cronjob/<cronname>`.

</details>

---

## Verify

```bash
# Check Job completion
k get job cleanup-job -o wide
k get pod -l job-name=cleanup-job

# Check logs
k logs -l job-name=cleanup-job --all-containers=true

# Check CronJob
k get cronjob hourly-backup

# Check if CronJob created a Job
k get job -l cronjob-name=hourly-backup

# Check triggered Job
k logs -l job-name=<triggered-job-name> --all-containers=true
```


When done, click **CHECK**.
