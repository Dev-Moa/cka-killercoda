#!/bin/bash
# Verify the pod exercise in the order of the question's checks.
# Exit 1 on the first failed check.

# Check 1: namespace exercise-01 exists.
kubectl get namespace exercise-01 &>/dev/null || {
  echo "namespace exercise-01 not found"
  exit 1
}
echo "namespace exercise-01 exists"

# Check 2: pod web is Running.
phase=$(kubectl get pod web -n exercise-01 -o jsonpath='{.status.phase}' 2>/dev/null)
[ "$phase" = "Running" ] || {
  echo "pod web not Running in exercise-01 (phase: ${phase:-not found})"
  exit 1
}
echo "pod web in exercise-01 is Running"

# Check 3: pod web image is nginx:1.27.
image=$(kubectl get pod web -n exercise-01 -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)
[ "$image" = "nginx:1.27" ] || {
  echo "pod web image is '${image:-missing}', expected nginx:1.27"
  exit 1
}
echo "pod web image is nginx:1.27"

# Check 4: labels app=web and version=v1 present, tier absent.
app=$(kubectl get pod web -n exercise-01 -o jsonpath='{.metadata.labels.app}' 2>/dev/null)
version=$(kubectl get pod web -n exercise-01 -o jsonpath='{.metadata.labels.version}' 2>/dev/null)
tier=$(kubectl get pod web -n exercise-01 -o jsonpath='{.metadata.labels.tier}' 2>/dev/null)
if [ "$app" = "web" ] && [ "$version" = "v1" ] && [ -z "$tier" ]; then
  echo "pod web labels correct: app=web, version=v1, no tier"
else
  echo "pod web labels wrong (app=${app:-missing}, version=${version:-missing}, tier=${tier:-absent})"
  exit 1
fi

# Check 5: requests memory 64Mi and cpu 100m.
mem=$(kubectl get pod web -n exercise-01 -o jsonpath='{.spec.containers[0].resources.requests.memory}' 2>/dev/null)
cpu=$(kubectl get pod web -n exercise-01 -o jsonpath='{.spec.containers[0].resources.requests.cpu}' 2>/dev/null)
if [ "$mem" = "64Mi" ] && [ "$cpu" = "100m" ]; then
  echo "pod web requests correct: memory 64Mi, cpu 100m"
else
  echo "pod web requests wrong (memory=${mem:-missing}, cpu=${cpu:-missing})"
  exit 1
fi

# Check 6: limits memory 128Mi and cpu 250m.
mem=$(kubectl get pod web -n exercise-01 -o jsonpath='{.spec.containers[0].resources.limits.memory}' 2>/dev/null)
cpu=$(kubectl get pod web -n exercise-01 -o jsonpath='{.spec.containers[0].resources.limits.cpu}' 2>/dev/null)
if [ "$mem" = "128Mi" ] && [ "$cpu" = "250m" ]; then
  echo "pod web limits correct: memory 128Mi, cpu 250m"
else
  echo "pod web limits wrong (memory=${mem:-missing}, cpu=${cpu:-missing})"
  exit 1
fi

echo "All checks passed: pod web in exercise-01 matches every requirement"
