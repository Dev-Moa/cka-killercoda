#!/bin/bash
# 20-pod-security-standards: PSS labels on the three namespaces, the two
# rejected privileged pods, and the audit-mode pod with its violation
# annotations. Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# Check 1: namespace exercise-20 exists
if kubectl get ns exercise-20 >/dev/null 2>&1; then
  echo "PASS 1: namespace exercise-20 exists"
else
  echo "FAIL 1: namespace exercise-20 not found"
  fail=1
fi

# Check 2: exercise-20 enforces restricted
level=$(kubectl get ns exercise-20 -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null)
if [ "$level" = "restricted" ]; then
  echo "PASS 2: exercise-20 has pod-security.kubernetes.io/enforce=restricted"
else
  echo "FAIL 2: exercise-20 enforce label expected 'restricted' (got '${level:-missing}')"
  fail=1
fi

# Check 3: pod rogue was rejected in exercise-20, so it must not exist
if kubectl get pod rogue -n exercise-20 >/dev/null 2>&1; then
  echo "FAIL 3: pod rogue exists in exercise-20 - restricted PSS should have rejected it"
  fail=1
else
  echo "PASS 3: pod rogue not in exercise-20 (privileged pod was rejected)"
fi

# Check 4: namespace exercise-20-baseline exists
if kubectl get ns exercise-20-baseline >/dev/null 2>&1; then
  echo "PASS 4: namespace exercise-20-baseline exists"
else
  echo "FAIL 4: namespace exercise-20-baseline not found"
  fail=1
fi

# Check 5: exercise-20-baseline enforces baseline
level=$(kubectl get ns exercise-20-baseline -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null)
if [ "$level" = "baseline" ]; then
  echo "PASS 5: exercise-20-baseline has pod-security.kubernetes.io/enforce=baseline"
else
  echo "FAIL 5: exercise-20-baseline enforce label expected 'baseline' (got '${level:-missing}')"
  fail=1
fi

# Check 6: pod priv-pod was rejected in exercise-20-baseline, so it must not exist
if kubectl get pod priv-pod -n exercise-20-baseline >/dev/null 2>&1; then
  echo "FAIL 6: pod priv-pod exists in exercise-20-baseline - baseline PSS should have rejected it"
  fail=1
else
  echo "PASS 6: pod priv-pod not in exercise-20-baseline (privileged pod was rejected)"
fi

# Check 7: at least one pod in exercise-20-baseline is Running (the non-root pod succeeded)
phases=$(kubectl get pods -n exercise-20-baseline -o jsonpath='{.items[*].status.phase}' 2>/dev/null)
if echo "$phases" | grep -q Running; then
  echo "PASS 7: a pod in exercise-20-baseline is Running"
else
  echo "FAIL 7: no Running pod in exercise-20-baseline (phases: ${phases:-none})"
  fail=1
fi

# Check 8: namespace exercise-20-audit exists
if kubectl get ns exercise-20-audit >/dev/null 2>&1; then
  echo "PASS 8: namespace exercise-20-audit exists"
else
  echo "FAIL 8: namespace exercise-20-audit not found"
  fail=1
fi

# Check 9: exercise-20-audit audits restricted
level=$(kubectl get ns exercise-20-audit -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/audit}' 2>/dev/null)
if [ "$level" = "restricted" ]; then
  echo "PASS 9: exercise-20-audit has pod-security.kubernetes.io/audit=restricted"
else
  echo "FAIL 9: exercise-20-audit audit label expected 'restricted' (got '${level:-missing}')"
  fail=1
fi

# Check 10: a pod in exercise-20-audit carries the audit-violations annotation
ann=$(kubectl get pods -n exercise-20-audit -o jsonpath='{.items[*].metadata.annotations.pod-security\.kubernetes\.io/audit-violations}' 2>/dev/null)
if [ -n "$ann" ]; then
  echo "PASS 10: a pod in exercise-20-audit has the pod-security.kubernetes.io/audit-violations annotation"
else
  echo "FAIL 10: no pod in exercise-20-audit has an audit-violations annotation"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - PSS labels, rejections, and audit mode all verified"
exit 0
