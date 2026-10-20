#!/bin/bash
# Verify the StatefulSet question end state, in the order of the
# question's verification list. Runs as root on controlplane.
# 1. Service mysql in default is headless (clusterIP None)
# 2. StatefulSet mysql in default has spec.replicas=2
# 3. Pods mysql-0 and mysql-1 in default are Running
# 4. At least 3 PVCs in default are Bound

# Check 1: headless Service
ip=$(kubectl get svc mysql -n default -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
if [ "$ip" != "None" ]; then
  echo "FAIL: service mysql in default missing or not headless (clusterIP: ${ip:-missing})"
  exit 1
fi
echo "PASS: service mysql in default is headless (clusterIP None)"

# Check 2: StatefulSet replicas
replicas=$(kubectl get statefulset mysql -n default -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "$replicas" != "2" ]; then
  echo "FAIL: statefulset mysql in default missing or replicas != 2 (found: ${replicas:-missing})"
  exit 1
fi
echo "PASS: statefulset mysql in default has replicas=2"

# Check 3: pods Running
for p in mysql-0 mysql-1; do
  phase=$(kubectl get pod "$p" -n default -o jsonpath='{.status.phase}' 2>/dev/null)
  if [ "$phase" != "Running" ]; then
    echo "FAIL: pod $p in default missing or not Running (phase: ${phase:-missing})"
    exit 1
  fi
done
echo "PASS: pods mysql-0 and mysql-1 in default are Running"

# Check 4: at least 3 Bound PVCs (volumeClaimTemplates created them)
bound=$(kubectl get pvc -n default --no-headers 2>/dev/null | awk '$2=="Bound" {c++} END {print c+0}')
if [ "$bound" -lt 3 ]; then
  echo "FAIL: fewer than 3 Bound PVCs in default (found $bound)"
  exit 1
fi
echo "PASS: at least 3 PVCs in default are Bound (found $bound)"

echo "StatefulSet question complete: headless Service, 2 replicas, pods Running, PVCs Bound"
