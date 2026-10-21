#!/bin/bash
# 08 step 1: node01 cordoned and drained, drain-test pods evicted off node01.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# Check 1: node01 is cordoned (spec.unschedulable=true)
unsched=$(kubectl get node node01 -o jsonpath='{.spec.unschedulable}' 2>/dev/null)
if [ "$unsched" = "true" ]; then
  echo "PASS 1: node01 is cordoned (SchedulingDisabled)"
else
  echo "FAIL 1: node01 is not cordoned (spec.unschedulable=${unsched:-missing})"
  fail=1
fi

# Check 2: deployment drain-test exists with 3 replicas
replicas=$(kubectl get deployment drain-test -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "$replicas" = "3" ]; then
  echo "PASS 2: deployment drain-test has 3 replicas"
else
  echo "FAIL 2: expected 3 replicas (got ${replicas:-not found})"
  fail=1
fi

# Check 3: all 3 drain-test pods are Ready
ready=$(kubectl get deployment drain-test -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$ready" = "3" ]; then
  echo "PASS 3: 3 drain-test pods Ready"
else
  echo "FAIL 3: expected 3 ready pods (readyReplicas=${ready:-0})"
  fail=1
fi

# Check 4: only DaemonSet pods remain on node01
non_ds=$(kubectl get pods -A --field-selector spec.nodeName=node01 \
  -o jsonpath='{range .items[*]}{.metadata.ownerReferences[0].kind}{"\n"}{end}' 2>/dev/null \
  | grep -v '^DaemonSet$' | grep -cv '^$')
if [ "$non_ds" = "0" ]; then
  echo "PASS 4: only DaemonSet pods remain on node01"
else
  echo "FAIL 4: ${non_ds} non-DaemonSet pod(s) still on node01"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - node01 cordoned and drained, drain-test Running elsewhere"
exit 0
