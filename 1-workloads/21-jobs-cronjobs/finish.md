# Jobs & CronJobs - done

The exam facts from this exercise:

- `completions: 3` means "finish successfully 3 times in total", not 3
  pods in parallel. With `parallelism: 1` the 3 runs happen one at a
  time; with `parallelism: 3` they run together.
- CronJobs live in the `batch/v1` API group — the same group as Job.
- A finished Job keeps its pods, so you can read their logs. Clean up
  test jobs, or the pods stay around.
- Job: `kubectl create job cleanup-job --image=busybox:1.37 --command -- echo "Cleanup complete"`,
  then patch `spec.completions` and `spec.parallelism`.
- CronJob: `schedule: "0 * * * *"` runs every hour;
  `successfulJobsHistoryLimit: 3` keeps 3 finished job records.
- Manual trigger: `kubectl create job my-run --from=cronjob/hourly-backup`
  creates a real Job right away.
- Check it: `kubectl get job cleanup-job`, `kubectl logs job/cleanup-job --all-containers=true`,
  `kubectl get cronjob hourly-backup`.

The exercise is based on exercise 21 in `cka-prep/exercises/1-workloads/`.
