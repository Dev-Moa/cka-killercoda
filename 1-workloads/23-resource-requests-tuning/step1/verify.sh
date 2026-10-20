#!/bin/bash
# Step 1: deployment web exists in exercise-23, its requests are below
# the impossible values, and all 3 pods are Running.

# Check 1: deployment web exists
kubectl get deploy web -n exercise-23 &>/dev/null || {
  echo "FAIL: deployment web not found in exercise-23"
  exit 1
}
echo "PASS: deployment web exists in exercise-23"

# Check 2: memory and cpu requests must be below the broken values (100Gi / 100 cores)
MEM=$(kubectl get deploy web -n exercise-23 -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}' 2>/dev/null)
CPU=$(kubectl get deploy web -n exercise-23 -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null)
if [ -z "$MEM" ] || [ -z "$CPU" ]; then
  echo "FAIL: memory and/or cpu request not found on deployment web in exercise-23"
  exit 1
fi

# memory to Mi: Gi -> x1024, Mi -> as-is, plain number = bytes -> /1048576
MEM_MI=$(case "$MEM" in
  *Gi) echo "$MEM" | sed 's/Gi$//' | awk '{print $1*1024}' ;;
  *Mi) echo "$MEM" | sed 's/Mi$//' ;;
  *)   echo "$MEM" | awk '{print $1/1048576}' ;;
esac)

# cpu to millicores: "m" suffix -> strip it, plain number = cores -> x1000
CPU_M=$(case "$CPU" in
  *m) echo "$CPU" | sed 's/m$//' ;;
  *)  echo "$CPU" | awk '{print $1*1000}' ;;
esac)

if ! awk -v m="$MEM_MI" -v c="$CPU_M" 'BEGIN { exit !(m < 102400 && c < 100000) }'; then
  echo "FAIL: requests not lowered enough: memory=$MEM cpu=$CPU (must be below 100Gi / 100 cores)"
  exit 1
fi
echo "PASS: requests lowered: memory=$MEM cpu=$CPU"

# Check 3: readyReplicas is 3 and no pod in exercise-23 is Pending
READY=$(kubectl get deploy web -n exercise-23 -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$READY" != "3" ]; then
  echo "FAIL: deployment web in exercise-23 has readyReplicas=$READY (need 3)"
  exit 1
fi
PENDING=$(kubectl get pods -n exercise-23 -o jsonpath='{range .items[*]}{.status.phase}{"\n"}{end}' 2>/dev/null | grep -c '^Pending$')
if [ "$PENDING" -ne 0 ]; then
  echo "FAIL: $PENDING pod(s) still Pending in exercise-23"
  exit 1
fi
echo "PASS: all 3 replicas of deployment web are Ready and no pod in exercise-23 is Pending"

echo "All checks passed: requests lowered and all 3 pods Running"
