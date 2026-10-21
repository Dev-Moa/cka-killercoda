#!/bin/bash
# W04: both pods Running, cmd-demo runs sleep with args 3600.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# Check 1: pod arg-demo is Running in default
phase=$(kubectl get pod arg-demo -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$phase" = "Running" ]; then
  echo "PASS 1: pod arg-demo is Running"
else
  echo "FAIL 1: pod arg-demo not Running (phase=${phase:-not found})"
  fail=1
fi

# Check 2: pod cmd-demo is Running in default
phase=$(kubectl get pod cmd-demo -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$phase" = "Running" ]; then
  echo "PASS 2: pod cmd-demo is Running"
else
  echo "FAIL 2: pod cmd-demo not Running (phase=${phase:-not found})"
  fail=1
fi

# Check 3: cmd-demo command is ["sleep"] and args are ["3600"]
cmd=$(kubectl get pod cmd-demo -o jsonpath='{.spec.containers[0].command}' 2>/dev/null)
args=$(kubectl get pod cmd-demo -o jsonpath='{.spec.containers[0].args}' 2>/dev/null)
if [ "$cmd" = '["sleep"]' ] && [ "$args" = '["3600"]' ]; then
  echo "PASS 3: cmd-demo runs command=[\"sleep\"] args=[\"3600\"]"
else
  echo "FAIL 3: cmd-demo expected command=[\"sleep\"] args=[\"3600\"] (got command=${cmd:-none} args=${args:-none})"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - arg-demo and cmd-demo Running, cmd-demo sleeps 3600"
exit 0
