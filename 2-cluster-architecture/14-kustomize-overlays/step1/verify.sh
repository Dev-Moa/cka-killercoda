#!/bin/bash
# 14-kustomize-overlays: base + staging overlay applied in ns exercise-14.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# Check 1: namespace exercise-14 exists
ns=$(kubectl get ns exercise-14 -o jsonpath='{.metadata.name}' 2>/dev/null)
if [ "$ns" = "exercise-14" ]; then
  echo "PASS 1: namespace exercise-14 exists"
else
  echo "FAIL 1: namespace exercise-14 missing (name=${ns:-not found})"
  fail=1
fi

# Check 2: Deployment app exists in exercise-14
name=$(kubectl get deploy app -n exercise-14 -o jsonpath='{.metadata.name}' 2>/dev/null)
if [ "$name" = "app" ]; then
  echo "PASS 2: Deployment app exists in exercise-14"
else
  echo "FAIL 2: Deployment app missing in exercise-14 (name=${name:-not found})"
  fail=1
fi

# Check 3: Deployment app has 3 replicas
replicas=$(kubectl get deploy app -n exercise-14 -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "$replicas" = "3" ]; then
  echo "PASS 3: Deployment app has 3 replicas"
else
  echo "FAIL 3: Deployment app replicas expected 3 (got ${replicas:-none})"
  fail=1
fi

# Check 4: Deployment app uses image nginx:1.27
image=$(kubectl get deploy app -n exercise-14 -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
if [ "$image" = "nginx:1.27" ]; then
  echo "PASS 4: Deployment app uses image nginx:1.27"
else
  echo "FAIL 4: Deployment app image expected nginx:1.27 (got ${image:-none})"
  fail=1
fi

# Check 5: Deployment app has label env=staging
label=$(kubectl get deploy app -n exercise-14 -o jsonpath='{.metadata.labels.env}' 2>/dev/null)
if [ "$label" = "staging" ]; then
  echo "PASS 5: Deployment app has label env=staging"
else
  echo "FAIL 5: Deployment app label env expected staging (got ${label:-none})"
  fail=1
fi

# Check 6: exactly 3 pods with label env=staging, all Running, in exercise-14
phases=$(kubectl get pods -n exercise-14 -l env=staging -o jsonpath='{.items[*].status.phase}' 2>/dev/null)
count=0
running=0
for p in $phases; do
  count=$((count + 1))
  [ "$p" = "Running" ] && running=$((running + 1))
done
if [ "$count" = "3" ] && [ "$running" = "3" ]; then
  echo "PASS 6: 3 pods with label env=staging are Running in exercise-14"
else
  echo "FAIL 6: expected 3 Running pods with env=staging (got ${count} pods, ${running} Running; phases=${phases:-none})"
  fail=1
fi

# Check 7: Service app-svc exists in exercise-14, ClusterIP, port 80
svc_name=$(kubectl get svc app-svc -n exercise-14 -o jsonpath='{.metadata.name}' 2>/dev/null)
svc_type=$(kubectl get svc app-svc -n exercise-14 -o jsonpath='{.spec.type}' 2>/dev/null)
svc_port=$(kubectl get svc app-svc -n exercise-14 -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
if [ "$svc_name" = "app-svc" ] && [ "$svc_type" = "ClusterIP" ] && [ "$svc_port" = "80" ]; then
  echo "PASS 7: Service app-svc is ClusterIP on port 80 in exercise-14"
else
  echo "FAIL 7: Service app-svc expected ClusterIP port 80 (got name=${svc_name:-none} type=${svc_type:-none} port=${svc_port:-none})"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - base and staging overlay applied in exercise-14"
exit 0
