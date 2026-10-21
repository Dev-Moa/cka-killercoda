#!/bin/bash
# 05-networkpolicy: three labelled pods in exercise-05 and the
# backend-policy NetworkPolicy graded by spec (ingress from
# role=frontend on port 80, egress UDP 53). Enforcement depends on the
# CNI, so no traffic test here.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

NS=exercise-05
fail=0

# Check 1: namespace exercise-05 exists
if kubectl get ns "$NS" >/dev/null 2>&1; then
  echo "PASS 1: namespace $NS exists"
else
  echo "FAIL 1: namespace $NS not found"
  fail=1
fi

# Checks 2-4: pods frontend, backend, attacker Running with their role label
n=2
for pod in frontend backend attacker; do
  phase=$(kubectl get pod "$pod" -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null)
  role=$(kubectl get pod "$pod" -n "$NS" -o jsonpath='{.metadata.labels.role}' 2>/dev/null)
  if [ "$phase" = "Running" ] && [ "$role" = "$pod" ]; then
    echo "PASS $n: pod $pod is Running with label role=$pod"
  else
    echo "FAIL $n: pod $pod expected Running with label role=$pod (got phase=${phase:-not found} role=${role:-none})"
    fail=1
  fi
  n=$((n + 1))
done

# Check 5: NetworkPolicy backend-policy exists in exercise-05
if kubectl get networkpolicy backend-policy -n "$NS" >/dev/null 2>&1; then
  echo "PASS 5: networkpolicy backend-policy exists in $NS"
else
  echo "FAIL 5: networkpolicy backend-policy not found in $NS"
  fail=1
fi

# Check 6: podSelector matches role=backend
sel=$(kubectl get networkpolicy backend-policy -n "$NS" -o jsonpath='{.spec.podSelector.matchLabels.role}' 2>/dev/null)
if [ "$sel" = "backend" ]; then
  echo "PASS 6: backend-policy podSelector is role=backend"
else
  echo "FAIL 6: backend-policy podSelector.matchLabels.role expected backend (got ${sel:-none})"
  fail=1
fi

# Check 7: policyTypes include Ingress and Egress
types=$(kubectl get networkpolicy backend-policy -n "$NS" -o jsonpath='{.spec.policyTypes}' 2>/dev/null)
case "$types" in
  *Ingress*Egress*|*Egress*Ingress*)
    echo "PASS 7: backend-policy policyTypes include Ingress and Egress"
    ;;
  *)
    echo "FAIL 7: backend-policy policyTypes expected Ingress and Egress (got ${types:-none})"
    fail=1
    ;;
esac

# Check 8: an ingress rule allows from podSelector role=frontend on port 80
# one line per rule: "<from role labels>|<protocol/port list>"
rules=$(kubectl get networkpolicy backend-policy -n "$NS" -o jsonpath='{range .spec.ingress[*]}{range .from[*]}{.podSelector.matchLabels.role}{" "}{end}{"|"}{range .ports[*]}{.protocol}{"/"}{.port}{" "}{end}{"\n"}{end}' 2>/dev/null)
# a hit = "frontend" among the from roles AND a "TCP/80" or "/80" token
# (protocol omitted defaults to TCP) among the ports
if echo "$rules" | grep -E '^([^|]* )?frontend [^|]*\|([^ ]* )*(TCP)?/80( |$)' >/dev/null; then
  echo "PASS 8: ingress rule allows from role=frontend on port 80"
else
  echo "FAIL 8: no ingress rule with from podSelector role=frontend and port 80 (rules: $(echo "$rules" | tr '\n' ';'))"
  fail=1
fi

# Check 9: an egress rule allows UDP port 53
eg=$(kubectl get networkpolicy backend-policy -n "$NS" -o jsonpath='{range .spec.egress[*]}{range .ports[*]}{.protocol}{"/"}{.port}{"\n"}{end}{end}' 2>/dev/null)
if echo "$eg" | grep -qx 'UDP/53'; then
  echo "PASS 9: egress rule allows UDP port 53 (DNS)"
else
  echo "FAIL 9: no egress rule with protocol UDP port 53 (egress ports: $(echo "$eg" | tr '\n' ' '))"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - pods labelled and backend-policy allows frontend:80 in, DNS out"
exit 0
