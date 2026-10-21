#!/bin/bash
# C02 step 2: the CronTab CRD is deleted and the object went with it.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

CRD=crontabs.stable.example.com

# Check 1: the CRD is gone
if kubectl get crd "$CRD" -o name >/dev/null 2>&1; then
  echo "FAIL 1: CRD $CRD still exists - delete it with kubectl delete crd $CRD"
  fail=1
else
  echo "PASS 1: CRD $CRD is deleted"
fi

# Check 2: the custom object went with it
if kubectl get "$CRD" my-new-cron-object -n default -o name >/dev/null 2>&1; then
  echo "FAIL 2: CronTab my-new-cron-object still exists in default"
  fail=1
else
  echo "PASS 2: CronTab my-new-cron-object is gone from default"
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - the CRD is deleted and the CronTab object went with it"
exit 0
