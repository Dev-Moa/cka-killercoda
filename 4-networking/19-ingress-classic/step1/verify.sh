#!/bin/bash
# 19-ingress-classic: Deployments web-app and api-app (nginx:1.28 x2),
# Services web-service:80 and api-service:8080 (ClusterIP, with
# endpoints), Ingress app-ingress with / -> web-service:80 and
# /api -> api-service:8080 (any pathType), default backend web-service,
# ingressClassName nginx. The ADDRESS is reported but not graded: the
# controller, not the candidate, fills it in.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

NS=exercise-19
fail=0

# Check 1: namespace exercise-19 exists
if kubectl get ns "$NS" >/dev/null 2>&1; then
  echo "PASS 1: namespace $NS exists"
else
  echo "FAIL 1: namespace $NS not found"
  fail=1
fi

# Checks 2-3: Deployments web-app and api-app, nginx:1.28, 2 replicas ready
n=2
for d in web-app api-app; do
  img=$(kubectl get deploy "$d" -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
  rep=$(kubectl get deploy "$d" -n "$NS" -o jsonpath='{.spec.replicas}' 2>/dev/null)
  ready=$(kubectl get deploy "$d" -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  if [ "$img" = "nginx:1.28" ] && [ "$rep" = "2" ] && [ "$ready" = "2" ]; then
    echo "PASS $n: deployment $d runs nginx:1.28 with 2/2 replicas ready"
  else
    echo "FAIL $n: deployment $d expected image nginx:1.28, replicas 2, ready 2 (got image=${img:-none} replicas=${rep:-none} ready=${ready:-0})"
    fail=1
  fi
  n=$((n + 1))
done

# Checks 4-5: Services ClusterIP on the right port with endpoints
for pair in web-service:80 api-service:8080; do
  svc=${pair%%:*}; port=${pair#*:}
  type=$(kubectl get svc "$svc" -n "$NS" -o jsonpath='{.spec.type}' 2>/dev/null)
  ports=$(kubectl get svc "$svc" -n "$NS" -o jsonpath='{.spec.ports[*].port}' 2>/dev/null)
  eps=$(kubectl get endpoints "$svc" -n "$NS" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
  if [ "$type" = "ClusterIP" ] && echo " $ports " | grep -q " $port " && [ -n "$eps" ]; then
    echo "PASS $n: service $svc is ClusterIP on port $port with endpoints ($eps)"
  else
    echo "FAIL $n: service $svc expected ClusterIP port $port with endpoints (got type=${type:-none} ports=${ports:-none} endpoints=${eps:-none})"
    fail=1
  fi
  n=$((n + 1))
done

# Check 6: Ingress app-ingress exists with ingressClassName nginx
cls=$(kubectl get ingress app-ingress -n "$NS" -o jsonpath='{.spec.ingressClassName}' 2>/dev/null)
if [ "$cls" = "nginx" ]; then
  echo "PASS 6: ingress app-ingress has ingressClassName nginx"
else
  echo "FAIL 6: ingress app-ingress missing or ingressClassName is '${cls:-none}' (expected nginx)"
  fail=1
fi

# Checks 7-8: path rules "/" -> web-service:80 and "/api" -> api-service:8080.
# The task names no pathType, so Prefix, Exact and ImplementationSpecific
# all pass; only path and backend are graded.
paths=$(kubectl get ingress app-ingress -n "$NS" -o jsonpath='{range .spec.rules[*].http.paths[*]}{.path}{" "}{.backend.service.name}{":"}{.backend.service.port.number}{"\n"}{end}' 2>/dev/null)
for want in "/ web-service:80" "/api api-service:8080"; do
  if echo "$paths" | grep -qx "$want"; then
    echo "PASS $n: ingress rule '$want' present"
  else
    echo "FAIL $n: ingress rule '$want' missing (rules: $(echo "$paths" | tr '\n' ';'))"
    fail=1
  fi
  n=$((n + 1))
done

# Check 9: default backend is web-service
def=$(kubectl get ingress app-ingress -n "$NS" -o jsonpath='{.spec.defaultBackend.service.name}' 2>/dev/null)
if [ "$def" = "web-service" ]; then
  echo "PASS 9: ingress default backend is web-service"
else
  echo "FAIL 9: ingress defaultBackend.service.name expected web-service (got ${def:-none})"
  fail=1
fi

# Info: ADDRESS assigned by the controller (not graded)
addr=""
for _ in 1 2 3 4 5 6; do
  addr=$(kubectl get ingress app-ingress -n "$NS" -o jsonpath='{.status.loadBalancer.ingress[*].ip}{.status.loadBalancer.ingress[*].hostname}' 2>/dev/null)
  [ -n "$addr" ] && break
  sleep 5
done
if [ -n "$addr" ]; then
  echo "INFO: ingress app-ingress ADDRESS is $addr"
else
  echo "INFO: ingress app-ingress has no ADDRESS yet (the controller fills it in; not graded)"
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - services have endpoints and app-ingress routes / and /api with class nginx"
exit 0
