#!/bin/bash
# Verify the StatefulSet question end state, in the order of the
# question's verification list. Runs as root on controlplane.
# Task 7 deletes the StatefulSet and keeps the PVCs, so two end states
# are valid:
#   a) the StatefulSet is gone (task 7 done) and its PVCs survived, or
#   b) the StatefulSet still exists, scaled down to 2, pods Running.
# 1. Service mysql in default is headless (clusterIP None)
# 2. StatefulSet mysql absent (task 7) OR spec.replicas=2 with mysql-0
#    and mysql-1 Running
# 3. At least 3 PVCs in default are Bound (volumeClaimTemplates created
#    them and they must survive the StatefulSet deletion)

# Check 1: headless Service
ip=$(kubectl get svc mysql -n default -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
if [ "$ip" != "None" ]; then
  echo "FAIL: service mysql in default missing or not headless (clusterIP: ${ip:-missing})"
  exit 1
fi
echo "PASS: service mysql in default is headless (clusterIP None)"

# Check 2: StatefulSet deleted (task 7) or scaled to 2 with pods Running
if kubectl get statefulset mysql -n default >/dev/null 2>&1; then
  replicas=$(kubectl get statefulset mysql -n default -o jsonpath='{.spec.replicas}' 2>/dev/null)
  if [ "$replicas" != "2" ]; then
    echo "FAIL: statefulset mysql in default still exists but replicas != 2 (found: ${replicas:-missing}); scale it to 2 or delete it (task 7)"
    exit 1
  fi
  for p in mysql-0 mysql-1; do
    phase=$(kubectl get pod "$p" -n default -o jsonpath='{.status.phase}' 2>/dev/null)
    if [ "$phase" != "Running" ]; then
      echo "FAIL: pod $p in default missing or not Running (phase: ${phase:-missing})"
      exit 1
    fi
  done
  echo "PASS: statefulset mysql in default has replicas=2 and pods mysql-0, mysql-1 are Running"
else
  echo "PASS: statefulset mysql is deleted (task 7 done)"
fi

# Check 3: at least 3 Bound PVCs (volumeClaimTemplates created them; they
# survive the StatefulSet deletion)
bound=$(kubectl get pvc -n default --no-headers 2>/dev/null | awk '$2=="Bound" {c++} END {print c+0}')
if [ "$bound" -lt 3 ]; then
  echo "FAIL: fewer than 3 Bound PVCs in default (found $bound) - the PVCs must survive the StatefulSet"
  exit 1
fi
echo "PASS: at least 3 PVCs in default are Bound (found $bound)"

echo "StatefulSet question complete: headless Service, StatefulSet scaled or deleted, PVCs Bound"
