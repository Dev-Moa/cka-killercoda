#!/bin/bash
# Jobs & CronJobs - all four checks from the question's verification list.
# Runs as root on controlplane with cluster-admin kubectl.

# 1. Job cleanup-job in default has completions=3 and parallelism=1
c=$(kubectl get job cleanup-job -n default -o jsonpath='{.spec.completions}' 2>/dev/null)
p=$(kubectl get job cleanup-job -n default -o jsonpath='{.spec.parallelism}' 2>/dev/null)
if [ "$c" = "3" ] && [ "$p" = "1" ]; then
  echo "PASS: job cleanup-job has completions=3 and parallelism=1"
else
  echo "FAIL: job cleanup-job missing or wrong completions/parallelism (completions=${c:-missing} parallelism=${p:-missing})"
  exit 1
fi

# 2. Job cleanup-job has status.succeeded=3
s=$(kubectl get job cleanup-job -n default -o jsonpath='{.status.succeeded}' 2>/dev/null)
if [ "$s" = "3" ]; then
  echo "PASS: job cleanup-job has succeeded 3 times"
else
  echo "FAIL: job cleanup-job missing or not done (succeeded=${s:-missing})"
  exit 1
fi

# 3. CronJob hourly-backup in default has schedule 0 * * * * and successfulJobsHistoryLimit=3
sch=$(kubectl get cronjob hourly-backup -n default -o jsonpath='{.spec.schedule}' 2>/dev/null)
hist=$(kubectl get cronjob hourly-backup -n default -o jsonpath='{.spec.successfulJobsHistoryLimit}' 2>/dev/null)
if [ "$sch" = "0 * * * *" ] && [ "$hist" = "3" ]; then
  echo "PASS: cronjob hourly-backup has schedule 0 * * * * and successfulJobsHistoryLimit=3"
else
  echo "FAIL: cronjob hourly-backup missing or wrong schedule/history (schedule=${sch:-missing} history=${hist:-missing})"
  exit 1
fi

# 4. At least one Job besides cleanup-job exists (the manual CronJob trigger)
others=$(kubectl get jobs -n default -o name 2>/dev/null | grep -v cleanup-job)
if [ -n "$others" ]; then
  echo "PASS: found another Job in default: $(echo "$others" | head -1)"
else
  echo "FAIL: no Job besides cleanup-job found in default - trigger the CronJob manually"
  exit 1
fi

echo "All checks passed: Job, CronJob, and the manual trigger are in place."
exit 0
