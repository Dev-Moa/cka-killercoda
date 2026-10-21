#!/bin/bash
# 28-network-policy-complex: namespaces frontend/backend/database, one
# Running pod per tier label, and NetworkPolicies graded by spec:
#   - in backend: a policy selecting tier=backend whose ingress allows
#     the frontend namespace on port 8080
#   - in database: a policy selecting tier=database whose ingress allows
#     the backend namespace on port 6379
#   - in every namespace: an egress rule allowing UDP 53
# Enforcement depends on the CNI, so no traffic test here.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# Checks 1-3: namespaces exist
n=1
for ns in frontend backend database; do
  if kubectl get ns "$ns" >/dev/null 2>&1; then
    echo "PASS $n: namespace $ns exists"
  else
    echo "FAIL $n: namespace $ns not found"
    fail=1
  fi
  n=$((n + 1))
done

# Checks 4-6: at least one Running pod with the tier label in each namespace
for ns in frontend backend database; do
  phases=$(kubectl get pods -n "$ns" -l tier="$ns" -o jsonpath='{.items[*].status.phase}' 2>/dev/null)
  if echo "$phases" | grep -q Running; then
    echo "PASS $n: a pod with label tier=$ns is Running in namespace $ns"
  else
    echo "FAIL $n: no Running pod with label tier=$ns in namespace $ns (phases: ${phases:-none})"
    fail=1
  fi
  n=$((n + 1))
done

# ns_matches <namespace> <matchLabels-json>: every key=value in the
# selector's matchLabels must be a label on the namespace
ns_matches() {
  local ns=$1 sel=$2 labels pair
  labels=$(kubectl get ns "$ns" -o jsonpath='{.metadata.labels}' 2>/dev/null)
  sel=$(echo "$sel" | sed 's/^{//; s/}$//')
  [ -z "$sel" ] && return 0            # {} = all namespaces, matches
  IFS=',' read -ra pairs <<< "$sel"
  for pair in "${pairs[@]}"; do
    case "$labels" in *"$pair"*) ;; *) return 1 ;; esac
  done
  return 0
}

# allow_rule <policy-ns> <target-tier> <source-ns> <port>: some policy in
# <policy-ns> selects tier=<target-tier> (or all pods) and has an ingress
# rule whose from[] has a namespaceSelector matching <source-ns> and
# whose ports[] include <port>
allow_rule() {
  local pns=$1 tier=$2 sns=$3 port=$4 pol sel rules rule from ports ok
  for pol in $(kubectl get networkpolicy -n "$pns" -o name 2>/dev/null); do
    sel=$(kubectl get "$pol" -n "$pns" -o jsonpath='{.spec.podSelector}' 2>/dev/null)
    case "$sel" in '{}'|*"\"tier\":\"$tier\""*) ;; *) continue ;; esac
    rules=$(kubectl get "$pol" -n "$pns" -o jsonpath='{range .spec.ingress[*]}{.from}{"|"}{range .ports[*]}{.protocol}{"/"}{.port}{" "}{end}{"\n"}{end}' 2>/dev/null)
    while IFS= read -r rule; do
      [ -z "$rule" ] && continue
      from=${rule%%|*}; ports=${rule#*|}
      echo " $ports" | grep -qE "(TCP|)/$port( |$)" || continue
      ok=0
      for m in $(echo "$from" | grep -o '"namespaceSelector":{[^}]*}}\?' | grep -o '"matchLabels":{[^}]*}' | sed 's/"matchLabels"://'); do
        ns_matches "$sns" "$m" && ok=1
      done
      echo "$from" | grep -q '"namespaceSelector":{}' && ok=1
      if [ "$ok" = "1" ]; then
        echo "${pol#networkpolicy.networking.k8s.io/}"
        return 0
      fi
    done <<< "$rules"
  done
  return 1
}

# Check 7: frontend -> backend on 8080
hit=$(allow_rule backend backend frontend 8080)
if [ -n "$hit" ]; then
  echo "PASS 7: policy $hit in backend allows ingress from namespace frontend on port 8080"
else
  echo "FAIL 7: no NetworkPolicy in backend selects tier=backend with an ingress rule from a namespaceSelector matching namespace frontend on port 8080"
  fail=1
fi

# Check 8: backend -> database on 6379
hit=$(allow_rule database database backend 6379)
if [ -n "$hit" ]; then
  echo "PASS 8: policy $hit in database allows ingress from namespace backend on port 6379"
else
  echo "FAIL 8: no NetworkPolicy in database selects tier=database with an ingress rule from a namespaceSelector matching namespace backend on port 6379"
  fail=1
fi

# Check 9: the tier pods are under an Ingress policy (deny by default for
# everything the rules above do not allow) - the policies found in 7/8
# already give that; here confirm policyTypes include Ingress
for ns in backend database; do
  types=$(kubectl get networkpolicy -n "$ns" -o jsonpath='{.items[*].spec.policyTypes}' 2>/dev/null)
  if echo "$types" | grep -q Ingress; then
    echo "PASS 9: namespace $ns has a policy with policyTypes Ingress (default-deny for selected pods)"
  else
    echo "FAIL 9: no policy in $ns has policyTypes Ingress"
    fail=1
  fi
done

# Checks 10-12: DNS egress UDP 53 allowed in each namespace
n=10
for ns in frontend backend database; do
  eg=$(kubectl get networkpolicy -n "$ns" -o jsonpath='{range .items[*]}{range .spec.egress[*]}{range .ports[*]}{.protocol}{"/"}{.port}{"\n"}{end}{end}{end}' 2>/dev/null)
  if echo "$eg" | grep -qx 'UDP/53'; then
    echo "PASS $n: namespace $ns has an egress rule allowing UDP 53 (DNS)"
  else
    echo "FAIL $n: no NetworkPolicy in $ns has an egress rule with protocol UDP port 53 (egress ports: $(echo "$eg" | tr '\n' ' '))"
    fail=1
  fi
  n=$((n + 1))
done

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - tiers labelled, cross-namespace allow rules on 8080 and 6379, DNS egress open"
exit 0
