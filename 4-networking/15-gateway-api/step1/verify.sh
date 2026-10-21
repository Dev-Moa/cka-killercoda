#!/bin/bash
# 15-gateway-api: Gateway web-gateway (existing GatewayClass, listener
# 80/HTTP), Deployment web (nginx:1.28 x2), Service web-svc:80,
# HTTPRoute web-route (parent web-gateway, PathPrefix /, backend
# web-svc:80), Gateway Programmed and route attached.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

NS=exercise-15
fail=0

# Check 1: namespace exercise-15 exists
if kubectl get ns "$NS" >/dev/null 2>&1; then
  echo "PASS 1: namespace $NS exists"
else
  echo "FAIL 1: namespace $NS not found"
  fail=1
fi

# Check 2: Gateway web-gateway references an existing GatewayClass
gc=$(kubectl get gateway web-gateway -n "$NS" -o jsonpath='{.spec.gatewayClassName}' 2>/dev/null)
if [ -n "$gc" ] && kubectl get gatewayclass "$gc" >/dev/null 2>&1; then
  echo "PASS 2: gateway web-gateway uses existing GatewayClass $gc"
else
  echo "FAIL 2: gateway web-gateway missing or gatewayClassName '${gc:-none}' is not an existing GatewayClass ($(kubectl get gatewayclass -o name 2>/dev/null | tr '\n' ' '))"
  fail=1
fi

# Check 3: a listener on port 80, protocol HTTP
listeners=$(kubectl get gateway web-gateway -n "$NS" -o jsonpath='{range .spec.listeners[*]}{.port}{"/"}{.protocol}{"\n"}{end}' 2>/dev/null)
if echo "$listeners" | grep -qx '80/HTTP'; then
  echo "PASS 3: gateway web-gateway has a listener on port 80 protocol HTTP"
else
  echo "FAIL 3: gateway web-gateway has no listener 80/HTTP (listeners: $(echo "$listeners" | tr '\n' ' '))"
  fail=1
fi

# Check 4: Deployment web, image nginx:1.28, 2 replicas ready
img=$(kubectl get deploy web -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
rep=$(kubectl get deploy web -n "$NS" -o jsonpath='{.spec.replicas}' 2>/dev/null)
ready=$(kubectl get deploy web -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$img" = "nginx:1.28" ] && [ "$rep" = "2" ] && [ "$ready" = "2" ]; then
  echo "PASS 4: deployment web runs nginx:1.28 with 2/2 replicas ready"
else
  echo "FAIL 4: deployment web expected image nginx:1.28, replicas 2, ready 2 (got image=${img:-none} replicas=${rep:-none} ready=${ready:-0})"
  fail=1
fi

# Check 5: Service web-svc is ClusterIP on port 80 with endpoints
type=$(kubectl get svc web-svc -n "$NS" -o jsonpath='{.spec.type}' 2>/dev/null)
ports=$(kubectl get svc web-svc -n "$NS" -o jsonpath='{.spec.ports[*].port}' 2>/dev/null)
eps=$(kubectl get endpoints web-svc -n "$NS" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
if [ "$type" = "ClusterIP" ] && echo " $ports " | grep -q ' 80 ' && [ -n "$eps" ]; then
  echo "PASS 5: service web-svc is ClusterIP on port 80 with endpoints ($eps)"
else
  echo "FAIL 5: service web-svc expected ClusterIP port 80 with endpoints (got type=${type:-none} ports=${ports:-none} endpoints=${eps:-none})"
  fail=1
fi

# Check 6: HTTPRoute web-route has parentRef web-gateway
parents=$(kubectl get httproute web-route -n "$NS" -o jsonpath='{.spec.parentRefs[*].name}' 2>/dev/null)
if echo " $parents " | grep -q ' web-gateway '; then
  echo "PASS 6: httproute web-route has parentRef web-gateway"
else
  echo "FAIL 6: httproute web-route missing or parentRefs do not name web-gateway (got ${parents:-none})"
  fail=1
fi

# Check 7: a rule matches PathPrefix / and routes to web-svc port 80
rules=$(kubectl get httproute web-route -n "$NS" -o jsonpath='{range .spec.rules[*]}{range .matches[*]}{.path.type}{":"}{.path.value}{" "}{end}{"|"}{range .backendRefs[*]}{.name}{":"}{.port}{" "}{end}{"\n"}{end}' 2>/dev/null)
if echo "$rules" | grep -E '^[^|]*PathPrefix:/( |\|)[^|]*\|.*(^| )web-svc:80( |$)' >/dev/null; then
  echo "PASS 7: httproute web-route matches PathPrefix / and routes to web-svc:80"
else
  echo "FAIL 7: no rule with match PathPrefix / and backendRef web-svc port 80 (rules: $(echo "$rules" | tr '\n' ';'))"
  fail=1
fi

# Check 8: Gateway condition Programmed is True (retry while the controller settles)
prog=""
for _ in 1 2 3 4 5 6; do
  prog=$(kubectl get gateway web-gateway -n "$NS" -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}' 2>/dev/null)
  [ "$prog" = "True" ] && break
  sleep 5
done
if [ "$prog" = "True" ]; then
  echo "PASS 8: gateway web-gateway is Programmed: True"
else
  echo "FAIL 8: gateway web-gateway Programmed is '${prog:-unset}' (needs the nginx-gateway controller running: kubectl get pods -n nginx-gateway)"
  fail=1
fi

# Check 9: HTTPRoute is attached - a parent status with Accepted True
acc=""
for _ in 1 2 3 4 5 6; do
  acc=$(kubectl get httproute web-route -n "$NS" -o jsonpath='{.status.parents[*].conditions[?(@.type=="Accepted")].status}' 2>/dev/null)
  echo "$acc" | grep -q True && break
  sleep 5
done
if echo "$acc" | grep -q True; then
  echo "PASS 9: httproute web-route is Accepted by its parent Gateway"
else
  echo "FAIL 9: httproute web-route has no parent status Accepted=True (got '${acc:-unset}') - check parentRefs name and namespace"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - web-gateway programmed, web-route attached and routing / to web-svc:80"
exit 0
