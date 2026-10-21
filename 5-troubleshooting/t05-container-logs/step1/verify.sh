#!/bin/bash
# T05: pod logs-demo in default Running with containers sim and sidecar
# (both busybox), sidecar runs sleep, and the sim container has written
# log lines (any content - never the wording).
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# Check 1: pod logs-demo is Running in default
phase=$(kubectl get pod logs-demo -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$phase" = "Running" ]; then
  echo "PASS 1: pod logs-demo is Running"
else
  echo "FAIL 1: pod logs-demo not Running (phase=${phase:-not found})"
  fail=1
fi

# Check 2: containers sim and sidecar, both image busybox
names=$(kubectl get pod logs-demo -o jsonpath='{range .spec.containers[*]}{.name}{"="}{.image}{" "}{end}' 2>/dev/null)
if echo " $names" | grep -q ' sim=busybox' && echo " $names" | grep -q ' sidecar=busybox'; then
  echo "PASS 2: containers sim and sidecar both use busybox ($names)"
else
  echo "FAIL 2: expected containers sim and sidecar with image busybox (got: ${names:-none})"
  fail=1
fi

# Check 3: both containers are running (ready)
rdy=$(kubectl get pod logs-demo -o jsonpath='{range .status.containerStatuses[*]}{.name}{"="}{.ready}{" "}{end}' 2>/dev/null)
if echo " $rdy" | grep -q ' sim=true' && echo " $rdy" | grep -q ' sidecar=true'; then
  echo "PASS 3: both containers are ready"
else
  echo "FAIL 3: a container is not ready (${rdy:-none})"
  fail=1
fi

# Check 4: sidecar runs sleep (command or args)
sc=$(kubectl get pod logs-demo -o jsonpath='{.spec.containers[?(@.name=="sidecar")].command} {.spec.containers[?(@.name=="sidecar")].args}' 2>/dev/null)
if echo "$sc" | grep -q 'sleep'; then
  echo "PASS 4: sidecar runs sleep ($sc)"
else
  echo "FAIL 4: sidecar should run sleep (got: ${sc:-none})"
  fail=1
fi

# Check 5: the sim container has written log lines (any content passes)
lines=0
for i in $(seq 1 5); do
  lines=$(kubectl logs logs-demo sim 2>/dev/null | grep -c .)
  [ "$lines" -ge 1 ] && break
  sleep 3
done
if [ "$lines" -ge 1 ]; then
  echo "PASS 5: kubectl logs logs-demo sim shows $lines line(s)"
else
  echo "FAIL 5: kubectl logs logs-demo sim is empty - sim is not printing"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - logs-demo Running, sim is streaming log lines"
exit 0
