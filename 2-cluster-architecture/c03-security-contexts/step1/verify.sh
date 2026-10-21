#!/bin/bash
# C03: sec-demo (container-level runAsUser 1000 + MAC_ADMIN) and
# sec-pod (pod-level runAsUser 1000, two ubuntu containers), both Running.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# Check 1: pod sec-demo is Running in default
phase=$(kubectl get pod sec-demo -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$phase" = "Running" ]; then
  echo "PASS 1: pod sec-demo is Running"
else
  echo "FAIL 1: pod sec-demo not Running (phase=${phase:-not found})"
  fail=1
fi

# Check 2: sec-demo runs image ubuntu
image=$(kubectl get pod sec-demo -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)
if [ "$image" = "ubuntu" ]; then
  echo "PASS 2: sec-demo image is ubuntu"
else
  echo "FAIL 2: sec-demo expected image ubuntu (got image=${image:-none})"
  fail=1
fi

# Check 3: sec-demo container-level runAsUser 1000
ru=$(kubectl get pod sec-demo -o jsonpath='{.spec.containers[0].securityContext.runAsUser}' 2>/dev/null)
if [ "$ru" = "1000" ]; then
  echo "PASS 3: sec-demo container runAsUser is 1000"
else
  echo "FAIL 3: sec-demo expected container runAsUser 1000 (got runAsUser=${ru:-none})"
  fail=1
fi

# Check 4: sec-demo adds the MAC_ADMIN capability
cap=$(kubectl get pod sec-demo -o jsonpath='{.spec.containers[0].securityContext.capabilities.add}' 2>/dev/null)
if [ "$cap" = '["MAC_ADMIN"]' ]; then
  echo 'PASS 4: sec-demo capabilities.add is ["MAC_ADMIN"]'
else
  echo "FAIL 4: sec-demo expected capabilities.add=[\"MAC_ADMIN\"] (got add=${cap:-none})"
  fail=1
fi

# Check 5: pod sec-pod is Running in default
phase=$(kubectl get pod sec-pod -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$phase" = "Running" ]; then
  echo "PASS 5: pod sec-pod is Running"
else
  echo "FAIL 5: pod sec-pod not Running (phase=${phase:-not found})"
  fail=1
fi

# Check 6: sec-pod pod-level runAsUser 1000
ru=$(kubectl get pod sec-pod -o jsonpath='{.spec.securityContext.runAsUser}' 2>/dev/null)
if [ "$ru" = "1000" ]; then
  echo "PASS 6: sec-pod pod-level runAsUser is 1000"
else
  echo "FAIL 6: sec-pod expected pod-level runAsUser 1000 (got runAsUser=${ru:-none})"
  fail=1
fi

# Check 7: sec-pod has two containers, both image ubuntu
images=$(kubectl get pod sec-pod -o jsonpath='{.spec.containers[*].image}' 2>/dev/null)
if [ "$images" = "ubuntu ubuntu" ]; then
  echo "PASS 7: sec-pod has two containers, both image ubuntu"
else
  echo "FAIL 7: sec-pod expected two ubuntu containers (got images=${images:-none})"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - sec-demo and sec-pod Running with runAsUser 1000 and MAC_ADMIN set"
exit 0
