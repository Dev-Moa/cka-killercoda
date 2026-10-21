#!/bin/bash
# 08 step 2: node01 uncordoned, drain-test scaled to 6 and spread across nodes.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# Check 1: node01 is uncordoned again
unsched=$(kubectl get node node01 -o jsonpath='{.spec.unschedulable}' 2>/dev/null)
if [ "$unsched" = "true" ]; then
  echo "FAIL 1: node01 is still cordoned (spec.unschedulable=true)"
  fail=1
else
  echo "PASS 1: node01 is uncordoned (spec.unschedulable=${unsched:-<null>})"
fi

# Check 2: deployment drain-test scaled to 6
replicas=$(kubectl get deployment drain-test -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "$replicas" = "6" ]; then
  echo "PASS 2: deployment drain-test has 6 replicas"
else
  echo "FAIL 2: expected 6 replicas (got ${replicas:-not found})"
  fail=1
fi

# Check 3: all 6 drain-test pods are Ready
ready=$(kubectl get deployment drain-test -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$ready" = "6" ]; then
  echo "PASS 3: 6 drain-test pods Ready"
else
  echo "FAIL 3: expected 6 ready pods (readyReplicas=${ready:-0})"
  fail=1
fi

# Check 4: at least one drain-test pod scheduled on node01
on_node01=$(kubectl get pods -l app=drain-test \
  -o jsonpath='{range .items[?(@.spec.nodeName=="node01")]}{.metadata.name}{"\n"}{end}' 2>/dev/null \
  | grep -c .)
if [ "$on_node01" -ge 1 ]; then
  echo "PASS 4: ${on_node01} drain-test pod(s) on node01"
else
  echo "FAIL 4: no drain-test pods on node01"
  fail=1
fi

# Check 5: pods spread - at least one drain-test pod on controlplane
on_cp=$(kubectl get pods -l app=drain-test \
  -o jsonpath='{range .items[?(@.spec.nodeName=="controlplane")]}{.metadata.name}{"\n"}{end}' 2>/dev/null \
  | grep -c .)
if [ "$on_cp" -ge 1 ]; then
  echo "PASS 5: ${on_cp} drain-test pod(s) on controlplane"
else
  echo "FAIL 5: no drain-test pods on controlplane"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - node01 uncordoned, drain-test at 6 replicas spread across both nodes"
exit 0
