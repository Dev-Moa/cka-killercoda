#!/bin/bash
# DaemonSet monitoring-daemon in default: exists, selector matches the
# template labels, tolerates the control-plane taint, and runs exactly
# one pod per node.

# 1. the DaemonSet exists in default
kubectl get ds monitoring-daemon &>/dev/null || {
  echo "daemonset monitoring-daemon not found in default"
  exit 1
}
echo "daemonset monitoring-daemon exists in default"

# 2. selector.matchLabels equals the template labels (app=monitoring-agent)
SEL=$(kubectl get ds monitoring-daemon -o jsonpath='{.spec.selector.matchLabels.app}' 2>/dev/null)
TMPL=$(kubectl get ds monitoring-daemon -o jsonpath='{.spec.template.metadata.labels.app}' 2>/dev/null)
if [ "$SEL" = "monitoring-agent" ] && [ "$TMPL" = "monitoring-agent" ]; then
  echo "daemonset monitoring-daemon selector matches template label app=monitoring-agent"
else
  echo "daemonset monitoring-daemon missing or selector/template label mismatch (selector='$SEL' template='$TMPL')"
  exit 1
fi

# 3. pod template tolerates the node-role.kubernetes.io/control-plane taint
#    (operator Exists, or Equal with empty value; effect NoSchedule or all)
TOLS=$(kubectl get ds monitoring-daemon -o jsonpath='{range .spec.template.spec.tolerations[*]}{.key}{"|"}{.operator}{"|"}{.value}{"|"}{.effect}{"\n"}{end}' 2>/dev/null)
MATCH=$(echo "$TOLS" | awk -F'|' '$1=="node-role.kubernetes.io/control-plane" && ($4=="NoSchedule" || $4=="") && ($2=="Exists" || $3=="") {print; exit}')
if [ -n "$MATCH" ]; then
  echo "daemonset monitoring-daemon tolerates the node-role.kubernetes.io/control-plane taint"
else
  echo "daemonset monitoring-daemon has no toleration for the node-role.kubernetes.io/control-plane taint"
  exit 1
fi

# 4. exactly one Running app=monitoring-agent pod on every node
NODES=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
if [ -z "$NODES" ]; then echo "no nodes found"; exit 1; fi
FAIL=""
for N in $NODES; do
  CNT=$(kubectl get pods -l app=monitoring-agent -o jsonpath='{range .items[*]}{.status.phase}{" "}{.spec.nodeName}{"\n"}{end}' 2>/dev/null | grep -c "^Running $N$")
  if [ "$CNT" -ne 1 ]; then
    FAIL="$FAIL node $N has $CNT Running monitoring-agent pods (need 1);"
  fi
done
if [ -n "$FAIL" ]; then
  echo "$FAIL"
  exit 1
fi
echo "exactly one Running app=monitoring-agent pod on every node"

echo "All checks passed: monitoring-daemon runs on every node"
exit 0
