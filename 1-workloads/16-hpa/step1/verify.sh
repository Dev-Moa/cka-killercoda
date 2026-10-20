#!/bin/bash
# Step 1: deployment, service, and HPA for load-app in exercise-16.
# Runs as root on controlplane with cluster-admin kubectl.

# 1. deployment load-app in exercise-16 sets a CPU request on its container
req=$(kubectl get deployment load-app -n exercise-16 -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null)
[ -n "$req" ] || {
  echo "deployment load-app in exercise-16 missing or has no CPU request"
  exit 1
}
echo "deployment load-app in exercise-16 sets requests.cpu=$req"

# 2. service load-svc in exercise-16 exposes port 80
ports=$(kubectl get svc load-svc -n exercise-16 -o jsonpath='{.spec.ports[*].port}' 2>/dev/null)
echo "$ports" | tr ' ' '\n' | grep -qx '80' || {
  echo "service load-svc in exercise-16 missing or does not expose port 80"
  exit 1
}
echo "service load-svc in exercise-16 exposes port 80"

# 3. hpa load-app in exercise-16 has minReplicas=1 and maxReplicas=5
min=$(kubectl get hpa load-app -n exercise-16 -o jsonpath='{.spec.minReplicas}' 2>/dev/null)
max=$(kubectl get hpa load-app -n exercise-16 -o jsonpath='{.spec.maxReplicas}' 2>/dev/null)
{ [ "$min" = "1" ] && [ "$max" = "5" ]; } || {
  echo "hpa load-app in exercise-16 missing or wrong min/max (min=${min:-missing} max=${max:-missing})"
  exit 1
}
echo "hpa load-app in exercise-16 has minReplicas=1 and maxReplicas=5"

# 4. hpa load-app in exercise-16 targets Resource cpu at Utilization 50
out=$(kubectl get hpa load-app -n exercise-16 -o jsonpath='{.spec.metrics[0].type} {.spec.metrics[0].resource.name} {.spec.metrics[0].resource.target.type} {.spec.metrics[0].resource.target.averageUtilization}' 2>/dev/null)
[ "$out" = "Resource cpu Utilization 50" ] || {
  echo "hpa load-app in exercise-16 metric wrong (found: ${out:-missing}; expected: Resource cpu Utilization 50)"
  exit 1
}
echo "hpa load-app in exercise-16 targets Resource cpu at Utilization 50"

echo "Deployment, service, and HPA for load-app are all correct"
