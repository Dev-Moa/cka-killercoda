#!/bin/bash
# 23: a 3-replica nginx:1.27 Deployment in exercise-23 (name is the
# candidate's choice - task 2 fixes none) whose requests were lowered
# below the intentionally-too-high 512Mi / 500m, with all 3 pods Running.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

NS=exercise-23
fail=0

# Check 1: namespace exercise-23 exists
if kubectl get ns "$NS" >/dev/null 2>&1; then
  echo "PASS 1: namespace $NS exists"
else
  echo "FAIL 1: namespace $NS not found"
  fail=1
fi

# Check 2: a Deployment with 3 replicas and image nginx:1.27 exists in exercise-23
deploy=$(kubectl get deploy -n "$NS" -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.replicas}{" "}{.spec.template.spec.containers[0].image}{"\n"}{end}' 2>/dev/null \
  | awk '$2=="3" && $3=="nginx:1.27" {print $1; exit}')
if [ -n "$deploy" ]; then
  echo "PASS 2: deployment $deploy in $NS has 3 replicas and image nginx:1.27"
else
  names=$(kubectl get deploy -n "$NS" -o jsonpath='{range .items[*]}{.metadata.name}{"="}{.spec.replicas}{"/"}{.spec.template.spec.containers[0].image}{" "}{end}' 2>/dev/null)
  echo "FAIL 2: no Deployment in $NS with 3 replicas and image nginx:1.27 (found: ${names:-none})"
  fail=1
fi

# Check 3: requests are set and lower than the intentionally-too-high 512Mi / 500m
MEM=$(kubectl get deploy "$deploy" -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}' 2>/dev/null)
CPU=$(kubectl get deploy "$deploy" -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null)
if [ -z "$MEM" ] || [ -z "$CPU" ]; then
  echo "FAIL 3: deployment ${deploy:-?} has no memory and/or cpu request (memory=${MEM:-none} cpu=${CPU:-none})"
  fail=1
else
  # memory to Mi: Gi -> x1024, Mi -> as-is, Ki -> /1024, plain bytes -> /1048576
  MEM_MI=$(case "$MEM" in
    *Gi) echo "$MEM" | sed 's/Gi$//' | awk '{print $1*1024}' ;;
    *Mi) echo "$MEM" | sed 's/Mi$//' ;;
    *Ki) echo "$MEM" | sed 's/Ki$//' | awk '{print $1/1024}' ;;
    *G)  echo "$MEM" | sed 's/G$//' | awk '{print $1*1000*1000*1000/1048576}' ;;
    *M)  echo "$MEM" | sed 's/M$//' | awk '{print $1*1000*1000/1048576}' ;;
    *)   echo "$MEM" | awk '{print $1/1048576}' ;;
  esac)
  # cpu to millicores: "m" suffix -> strip it, plain number = cores -> x1000
  CPU_M=$(case "$CPU" in
    *m) echo "$CPU" | sed 's/m$//' ;;
    *)  echo "$CPU" | awk '{print $1*1000}' ;;
  esac)
  if awk -v m="$MEM_MI" -v c="$CPU_M" 'BEGIN { exit !(m < 512 && c < 500) }'; then
    echo "PASS 3: deployment $deploy requests lowered to memory=$MEM cpu=$CPU (below 512Mi / 500m)"
  else
    echo "FAIL 3: deployment $deploy requests memory=$MEM cpu=$CPU are not below the starting 512Mi / 500m (task 6)"
    fail=1
  fi
fi

# Check 4: all 3 replicas Ready and no pod in exercise-23 Pending
READY=$(kubectl get deploy "$deploy" -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
PENDING=$(kubectl get pods -n "$NS" -o jsonpath='{range .items[*]}{.status.phase}{"\n"}{end}' 2>/dev/null | grep -c '^Pending$')
if [ "$READY" = "3" ] && [ "$PENDING" -eq 0 ]; then
  echo "PASS 4: deployment ${deploy} has 3 ready replicas and no pod in $NS is Pending"
else
  echo "FAIL 4: deployment ${deploy:-?} readyReplicas=${READY:-0} (need 3), ${PENDING:-0} pod(s) Pending in $NS"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - requests lowered and all 3 pods Running"
exit 0
