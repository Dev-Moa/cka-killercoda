#!/bin/bash
# Check 1: PriorityClass high-priority exists with value 999999.
VALUE=$(kubectl get priorityclass high-priority -o jsonpath='{.value}' 2>/dev/null)
if [ "$VALUE" = "999999" ]; then
  echo "priorityclass high-priority exists with value 999999"
else
  echo "priorityclass high-priority missing or has value=$VALUE (need 999999)"
  exit 1
fi

# Check 2: deployment critical-app in exercise-24 has priorityClassName high-priority.
PC=$(kubectl get deploy critical-app -n exercise-24 -o jsonpath='{.spec.template.spec.priorityClassName}' 2>/dev/null)
if [ "$PC" = "high-priority" ]; then
  echo "deployment critical-app in exercise-24 has priorityClassName high-priority"
else
  echo "deployment critical-app missing in exercise-24 or priorityClassName='$PC' (need high-priority)"
  exit 1
fi

# Check 3: a Running pod of deployment critical-app whose spec.priorityClassName is high-priority.
POD=$(kubectl get pods -n exercise-24 -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.phase}{" "}{.spec.priorityClassName}{"\n"}{end}' 2>/dev/null \
  | awk '$2=="Running" && $3=="high-priority" {print $1; exit}')
if [ -z "$POD" ]; then
  echo "no Running pod with priorityClassName high-priority in exercise-24"
  exit 1
fi
# Walk pod -> ReplicaSet -> Deployment to confirm it belongs to critical-app.
RS=$(kubectl get pod "$POD" -n exercise-24 -o jsonpath='{.metadata.ownerReferences[0].name}' 2>/dev/null)
DEPLOY=$(kubectl get rs "$RS" -n exercise-24 -o jsonpath='{.metadata.ownerReferences[0].name}' 2>/dev/null)
if [ "$DEPLOY" = "critical-app" ]; then
  echo "pod $POD is Running and belongs to deployment critical-app with priorityClassName high-priority"
else
  echo "pod $POD has high-priority but does not belong to deployment critical-app"
  exit 1
fi

# Check 4: at least 2 deployments in exercise-24, and at least one has no priorityClassName.
N=$(kubectl get deploy -n exercise-24 -o name 2>/dev/null | wc -l)
if [ "$N" -lt 2 ]; then
  echo "need at least 2 deployments in exercise-24 (found $N)"
  exit 1
fi
LOW=$(kubectl get deploy -n exercise-24 -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.template.spec.priorityClassName}{"\n"}{end}' 2>/dev/null | awk '$2=="" {print $1; exit}')
if [ -n "$LOW" ]; then
  echo "deployment $LOW in exercise-24 has no priorityClassName (lower-priority comparison present)"
else
  echo "every deployment in exercise-24 sets a priorityClassName; a comparison deployment without one is missing"
  exit 1
fi

echo "All checks passed: PriorityClass, patched deployment, running pod, and comparison deployment"
exit 0
