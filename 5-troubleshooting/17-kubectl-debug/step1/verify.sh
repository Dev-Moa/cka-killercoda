#!/bin/bash
# 17: pod broken-app in exercise-17 Running with an ephemeral debug
# container (busybox:1.36, --target=broken-app), and a node debug pod
# that mounts the host filesystem at /host.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# Check 1: namespace exercise-17 exists
if kubectl get ns exercise-17 >/dev/null 2>&1; then
  echo "PASS 1: namespace exercise-17 exists"
else
  echo "FAIL 1: namespace exercise-17 not found"
  fail=1
fi

# Check 2: pod broken-app is Running with image nginx:1.27
phase=$(kubectl get pod broken-app -n exercise-17 -o jsonpath='{.status.phase}' 2>/dev/null)
image=$(kubectl get pod broken-app -n exercise-17 -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)
if [ "$phase" = "Running" ] && [ "$image" = "nginx:1.27" ]; then
  echo "PASS 2: pod broken-app is Running with image nginx:1.27"
else
  echo "FAIL 2: pod broken-app expected Running with nginx:1.27 (phase=${phase:-not found} image=${image:-none})"
  fail=1
fi

# Check 3: an ephemeral container with image busybox:1.36 was added to broken-app
eph=$(kubectl get pod broken-app -n exercise-17 -o jsonpath='{range .spec.ephemeralContainers[*]}{.name}{"|"}{.image}{"|"}{.targetContainerName}{"\n"}{end}' 2>/dev/null)
if echo "$eph" | grep -q '|busybox:1.36|'; then
  echo "PASS 3: broken-app has an ephemeral debug container with image busybox:1.36"
else
  echo "FAIL 3: no ephemeral container with image busybox:1.36 on broken-app (found: ${eph:-none})"
  fail=1
fi

# Check 4: that debug container targets broken-app (shared process namespace)
if echo "$eph" | grep -q '|busybox:1.36|broken-app$'; then
  echo "PASS 4: the debug container targets container broken-app (--target)"
else
  echo "FAIL 4: the busybox:1.36 debug container has no --target=broken-app (found: ${eph:-none})"
  fail=1
fi

# Check 5: a node debug pod exists (any namespace, any phase) with the
# host root mounted at /host
nd=$(kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"/"}{.metadata.name}{"|"}{.spec.volumes[*].hostPath.path}{"|"}{.spec.containers[0].volumeMounts[*].mountPath}{"\n"}{end}' 2>/dev/null \
  | grep '/node-debugger-' | grep '|/|' | grep '|.*/host' | head -1)
if [ -n "$nd" ]; then
  echo "PASS 5: node debug pod found with host filesystem at /host (${nd%%|*})"
else
  echo "FAIL 5: no node-debugger pod with hostPath / mounted at /host found (run kubectl debug node/<node>)"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - pod debug with --target and node debug both done"
exit 0
