#!/bin/bash
# 12 step 2: PVC my-pvc deleted, PV my-pv Released (reclaim policy Retain).
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0
NS=exercise-12

# Check 1: PVC my-pvc is gone from exercise-12
if kubectl get pvc my-pvc -n "$NS" >/dev/null 2>&1; then
  ts=$(kubectl get pvc my-pvc -n "$NS" -o jsonpath='{.metadata.deletionTimestamp}' 2>/dev/null)
  if [ -n "$ts" ]; then
    echo "FAIL 1: PVC my-pvc is still Terminating - a pod still uses it; delete the pod first"
  else
    echo "FAIL 1: PVC my-pvc still exists in $NS - delete it (task 8)"
  fi
  fail=1
else
  echo "PASS 1: PVC my-pvc is deleted from $NS"
fi

# Check 2: PV my-pv still exists with reclaim policy Retain
policy=$(kubectl get pv my-pv -o jsonpath='{.spec.persistentVolumeReclaimPolicy}' 2>/dev/null)
if [ "$policy" = "Retain" ]; then
  echo "PASS 2: PV my-pv still exists with reclaim policy Retain"
else
  echo "FAIL 2: PV my-pv expected to exist with reclaimPolicy=Retain (got ${policy:-PV not found})"
  fail=1
fi

# Check 3: PV my-pv is Released (not Available, not Bound)
phase=$(kubectl get pv my-pv -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$phase" = "Released" ]; then
  echo "PASS 3: PV my-pv is Released"
else
  echo "FAIL 3: PV my-pv expected phase=Released (got ${phase:-none})"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - my-pvc deleted, my-pv Released with Retain"
exit 0
