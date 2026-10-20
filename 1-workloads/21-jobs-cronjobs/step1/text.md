# Jobs & CronJobs

Jobs run pods to completion and finish when the work is done. Unlike
Deployments, which keep pods running, a Job retries a failed run instead
of restarting the pod. CronJobs schedule Jobs on a schedule, like cron in
Linux. The exam asks you to create both, so know the completions,
parallelism, and history-limit fields.

Work in the `default` namespace.

1. Create a Job named `cleanup-job` that runs image `busybox:1.37` with
   the command `echo "Cleanup complete"`. It must complete successfully
   3 times (`completions: 3`), one pod at a time (`parallelism: 1`).

2. Verify the Job reaches `3/3` completions and check the pod logs - each
   pod prints `Cleanup complete`.

3. Create a CronJob named `hourly-backup` that runs every hour (schedule
   `0 * * * *`). Use the same `busybox:1.37` image and keep 3 successful
   job histories (`successfulJobsHistoryLimit: 3`).

4. List the CronJobs and note the next scheduled time.

5. Manually trigger the CronJob once: create a Job from it with
   `kubectl create job <name> --from=cronjob/hourly-backup`.

6. Verify the manual Job ran and its logs show the output.

When done, click **CHECK**.
