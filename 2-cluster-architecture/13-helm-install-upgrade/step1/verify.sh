#!/bin/bash
# 13: helm release web in namespace exercise-13: installed, upgraded
# (replicaCount 3), then rolled back to revision 1 (replicaCount 2).
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# Check 1: namespace exercise-13 exists
if kubectl get ns exercise-13 >/dev/null 2>&1; then
  echo "PASS 1: namespace exercise-13 exists"
else
  echo "FAIL 1: namespace exercise-13 not found"
  fail=1
fi

# Check 2: deployment web-nginx exists in exercise-13
if kubectl get deploy web-nginx -n exercise-13 >/dev/null 2>&1; then
  echo "PASS 2: deployment web-nginx exists in exercise-13"
else
  echo "FAIL 2: deployment web-nginx not found in exercise-13"
  fail=1
fi

# Check 3: helm release web has >= 3 revisions (install + upgrade + rollback)
revs=$(kubectl get secrets -n exercise-13 -o name 2>/dev/null \
  | grep -c '^secret/sh\.helm\.release\.v1\.web\.v[0-9][0-9]*$' || true)
revs=${revs:-0}
if [ "$revs" -ge 3 ]; then
  echo "PASS 3: helm release web has ${revs} revisions (install + upgrade + rollback)"
else
  echo "FAIL 3: expected >=3 revisions for helm release web (got ${revs})"
  fail=1
fi

# Check 4: deployment web-nginx has spec.replicas == 2 (rollback result)
replicas=$(kubectl get deploy web-nginx -n exercise-13 \
  -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "$replicas" = "2" ]; then
  echo "PASS 4: deployment web-nginx spec.replicas is 2"
else
  echo "FAIL 4: expected web-nginx spec.replicas=2 (got ${replicas:-not found})"
  fail=1
fi

# Check 5: 2 ready pods (web-nginx status.readyReplicas == 2), poll briefly
ready=""
for _ in $(seq 1 30); do
  kubectl get deploy web-nginx -n exercise-13 >/dev/null 2>&1 || break
  ready=$(kubectl get deploy web-nginx -n exercise-13 \
    -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  [ "$ready" = "2" ] && break
  sleep 2
done
if [ "$ready" = "2" ]; then
  echo "PASS 5: 2 ready pods for web-nginx in exercise-13"
else
  echo "FAIL 5: expected 2 ready pods for web-nginx (got ${ready:-none})"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - web in exercise-13 has 2 replicas and >=3 revisions (install, upgrade, rollback)"
exit 0
