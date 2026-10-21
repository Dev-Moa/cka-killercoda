#!/bin/bash
# 20-pod-security-standards: PSS labels on the three namespaces, the two
# rejected privileged pods, and the audit-mode pod that was allowed in.
# (Audit mode writes pod-security.kubernetes.io/audit-violations into the
# audit-log event, never onto the pod object, so the pod cannot be
# checked for that annotation - only for having been admitted.)
# Evidence-only output, also written to /tmp/check-report.txt.
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

# Check 10: exercise-20-audit does not ENFORCE restricted - task 7 asks for
# restricted in audit mode only; with enforce=restricted the task 8 pod
# would be rejected instead of allowed
enforce=$(kubectl get ns exercise-20-audit -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null)
if [ "$enforce" != "restricted" ]; then
  echo "PASS 10: exercise-20-audit has no enforce=restricted label (enforce='${enforce:-none}')"
else
  echo "FAIL 10: exercise-20-audit enforces restricted - audit mode must only audit, remove the enforce label"
  fail=1
fi

# Check 11: a pod was admitted in exercise-20-audit and is Running (task 8:
# the violating pod succeeds in audit mode)
phases=$(kubectl get pods -n exercise-20-audit -o jsonpath='{.items[*].status.phase}' 2>/dev/null)
if echo "$phases" | grep -q Running; then
  echo "PASS 11: a pod in exercise-20-audit is Running (allowed by audit mode)"
else
  echo "FAIL 11: no Running pod in exercise-20-audit (phases: ${phases:-none}) - audit mode must let the pod in"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - PSS labels, rejections, and audit mode all verified"
exit 0
