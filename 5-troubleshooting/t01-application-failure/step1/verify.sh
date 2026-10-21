#!/bin/bash
# T01: web-service (same object, not recreated) has an endpoint and
# answers; pods db and cache are Running and ready in namespace shop.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

NS=shop
fail=0

# Check 1: web-service still exists and is the original object (not deleted + recreated)
uid=$(kubectl get svc web-service -n $NS -o jsonpath='{.metadata.uid}' 2>/dev/null)
orig=$(cat /tmp/exam/web-service-uid.txt 2>/dev/null)
if [ -n "$uid" ] && { [ -z "$orig" ] || [ "$uid" = "$orig" ]; }; then
  echo "PASS 1: Service web-service exists in $NS and was not deleted"
else
  echo "FAIL 1: Service web-service missing in $NS or was deleted and recreated (uid=${uid:-none}, original=${orig:-unknown})"
  fail=1
fi

# Check 2: web-service has at least one endpoint (selector matches the webapp pod)
eps=""
for i in $(seq 1 6); do
  eps=$(kubectl get endpointslices -n $NS -l kubernetes.io/service-name=web-service -o jsonpath='{.items[*].endpoints[*].addresses[*]}' 2>/dev/null)
  [ -n "$eps" ] && break
  sleep 3
done
if [ -n "$eps" ]; then
  echo "PASS 2: web-service has endpoint(s): $eps"
else
  sel=$(kubectl get svc web-service -n $NS -o jsonpath='{.spec.selector}' 2>/dev/null)
  echo "FAIL 2: web-service has no endpoints (selector=${sel:-none}; compare with the pod labels)"
  fail=1
fi

# Check 3: web-service answers on its ClusterIP:8080 (tested from controlplane)
ip=$(kubectl get svc web-service -n $NS -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
port=$(kubectl get svc web-service -n $NS -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
code=""
for i in $(seq 1 5); do
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://${ip}:${port}/" 2>/dev/null)
  [ "$code" = "200" ] && break
  sleep 3
done
if [ "$code" = "200" ]; then
  echo "PASS 3: web-service answers HTTP 200 on ${ip}:${port}"
else
  echo "FAIL 3: web-service does not answer on ${ip:-?}:${port:-?} (http_code=${code:-none})"
  fail=1
fi

# Check 4: pod db is Running and its container is ready (no crash loop)
phase=$(kubectl get pod db -n $NS -o jsonpath='{.status.phase}' 2>/dev/null)
ready=$(kubectl get pod db -n $NS -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)
waiting=$(kubectl get pod db -n $NS -o jsonpath='{.status.containerStatuses[0].state.waiting.reason}' 2>/dev/null)
if [ "$phase" = "Running" ] && [ "$ready" = "true" ]; then
  echo "PASS 4: pod db is Running and ready"
else
  echo "FAIL 4: pod db not healthy (phase=${phase:-not found} ready=${ready:-false} waiting=${waiting:-none})"
  fail=1
fi

# Check 5: pod cache is Running with a redis image and its container is ready
phase=$(kubectl get pod cache -n $NS -o jsonpath='{.status.phase}' 2>/dev/null)
ready=$(kubectl get pod cache -n $NS -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)
image=$(kubectl get pod cache -n $NS -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)
waiting=$(kubectl get pod cache -n $NS -o jsonpath='{.status.containerStatuses[0].state.waiting.reason}' 2>/dev/null)
case "$image" in
  redis*|*/redis*) img_ok=1 ;;
  *) img_ok=0 ;;
esac
if [ "$phase" = "Running" ] && [ "$ready" = "true" ] && [ "$img_ok" = "1" ]; then
  echo "PASS 5: pod cache is Running and ready with image $image"
else
  echo "FAIL 5: pod cache not healthy (phase=${phase:-not found} ready=${ready:-false} image=${image:-none} waiting=${waiting:-none})"
  fail=1
fi

# Check 6: no pod in shop is stuck (every pod Running)
phases=$(kubectl get pods -n $NS -o jsonpath='{range .items[*]}{.metadata.name}{"="}{.status.phase}{" "}{end}' 2>/dev/null)
stuck=$(echo "$phases" | tr ' ' '\n' | grep . | grep -v -e '=Running$' -e '=Succeeded$' | tr '\n' ' ')
if [ -n "$phases" ] && [ -z "$stuck" ]; then
  echo "PASS 6: every pod in $NS is Running ($phases)"
else
  echo "FAIL 6: pod(s) in $NS not Running: ${stuck:-none found at all}"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - web-service answers, db and cache Running"
exit 0
