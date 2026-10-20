#!/bin/bash
# Verify the PriorityClass question: two PriorityClasses and two pods,
# each pod Running with the right class and priority.

# Check 1: priorityclass high-priority has value 1000 and
# preemptionPolicy PreemptLowerPriority.
v=$(kubectl get priorityclass high-priority -o jsonpath='{.value}' 2>/dev/null)
pp=$(kubectl get priorityclass high-priority -o jsonpath='{.preemptionPolicy}' 2>/dev/null)
if [ "$v" = "1000" ] && [ "$pp" = "PreemptLowerPriority" ]; then
  echo "priorityclass high-priority has value 1000 and preemptionPolicy PreemptLowerPriority"
else
  echo "priorityclass high-priority missing or wrong value/preemptionPolicy (value=${v:-missing} policy=${pp:-missing})"
  exit 1
fi

# Check 2: priorityclass low-priority has value 10 and
# preemptionPolicy Never.
v=$(kubectl get priorityclass low-priority -o jsonpath='{.value}' 2>/dev/null)
pp=$(kubectl get priorityclass low-priority -o jsonpath='{.preemptionPolicy}' 2>/dev/null)
if [ "$v" = "10" ] && [ "$pp" = "Never" ]; then
  echo "priorityclass low-priority has value 10 and preemptionPolicy Never"
else
  echo "priorityclass low-priority missing or wrong value/preemptionPolicy (value=${v:-missing} policy=${pp:-missing})"
  exit 1
fi

# Check 3: pod critical-app in default is Running with
# priorityClassName high-priority and priority 1000.
phase=$(kubectl get pod critical-app -n default -o jsonpath='{.status.phase}' 2>/dev/null)
pc=$(kubectl get pod critical-app -n default -o jsonpath='{.spec.priorityClassName}' 2>/dev/null)
prio=$(kubectl get pod critical-app -n default -o jsonpath='{.spec.priority}' 2>/dev/null)
if [ "$phase" = "Running" ] && [ "$pc" = "high-priority" ] && [ "$prio" = "1000" ]; then
  echo "pod critical-app in default is Running with priorityClassName high-priority and priority 1000"
else
  echo "pod critical-app in default wrong state (phase=${phase:-missing} priorityClassName=${pc:-missing} priority=${prio:-missing})"
  exit 1
fi

# Check 4: pod background-job in default is Running with
# priorityClassName low-priority and priority 10.
phase=$(kubectl get pod background-job -n default -o jsonpath='{.status.phase}' 2>/dev/null)
pc=$(kubectl get pod background-job -n default -o jsonpath='{.spec.priorityClassName}' 2>/dev/null)
prio=$(kubectl get pod background-job -n default -o jsonpath='{.spec.priority}' 2>/dev/null)
if [ "$phase" = "Running" ] && [ "$pc" = "low-priority" ] && [ "$prio" = "10" ]; then
  echo "pod background-job in default is Running with priorityClassName low-priority and priority 10"
else
  echo "pod background-job in default wrong state (phase=${phase:-missing} priorityClassName=${pc:-missing} priority=${prio:-missing})"
  exit 1
fi

echo "All checks passed: PriorityClasses and pods are correct"
