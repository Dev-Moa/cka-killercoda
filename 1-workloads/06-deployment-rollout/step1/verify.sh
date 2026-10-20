#!/bin/bash
# Step 1: webapp is rolled back to nginx:1.28, healthy, with the strategy,
# the change-cause annotation, and at least 3 rollout revisions.

# 1. deployment webapp exists in exercise-06 with spec.replicas=3
replicas=$(kubectl get deployment webapp -n exercise-06 -o jsonpath='{.spec.replicas}' 2>/dev/null)
[ "$replicas" = "3" ] || {
  echo "deployment webapp missing in exercise-06 or replicas=${replicas:-none}, expected 3"
  exit 1
}
echo "deployment webapp exists in exercise-06 with 3 replicas"

# 2. template image is nginx:1.28 (back after the rollback)
image=$(kubectl get deployment webapp -n exercise-06 -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
[ "$image" = "nginx:1.28" ] || {
  echo "deployment webapp template image is '${image:-missing}', expected nginx:1.28"
  exit 1
}
echo "deployment webapp template image is nginx:1.28"

# 3. all 3 replicas are Ready
ready=$(kubectl get deployment webapp -n exercise-06 -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[ "$ready" = "3" ] || {
  echo "deployment webapp has ${ready:-0} ready replicas, expected 3"
  exit 1
}
echo "deployment webapp has 3 ready replicas"

# 4. strategy RollingUpdate with maxSurge=1 and maxUnavailable=0
type=$(kubectl get deployment webapp -n exercise-06 -o jsonpath='{.spec.strategy.type}' 2>/dev/null)
surge=$(kubectl get deployment webapp -n exercise-06 -o jsonpath='{.spec.strategy.rollingUpdate.maxSurge}' 2>/dev/null)
unavail=$(kubectl get deployment webapp -n exercise-06 -o jsonpath='{.spec.strategy.rollingUpdate.maxUnavailable}' 2>/dev/null)
{ [ "$type" = "RollingUpdate" ] && [ "$surge" = "1" ] && [ "$unavail" = "0" ]; } || {
  echo "strategy wrong (type=${type:-missing}, maxSurge=${surge:-missing}, maxUnavailable=${unavail:-missing})"
  exit 1
}
echo "strategy RollingUpdate with maxSurge=1 and maxUnavailable=0"

# 5. kubernetes.io/change-cause annotation present on the deployment
ann=$(kubectl get deployment webapp -n exercise-06 -o jsonpath='{.metadata.annotations.kubernetes\.io/change-cause}' 2>/dev/null)
[ -n "$ann" ] || {
  echo "kubernetes.io/change-cause annotation missing on deployment webapp"
  exit 1
}
echo "kubernetes.io/change-cause annotation present on deployment webapp"

# 6. rollout history has at least 3 revisions (create, update, rollback)
count=$(kubectl rollout history deployment/webapp -n exercise-06 2>/dev/null | grep -cE '^[0-9]+[[:space:]]')
if [ "${count:-0}" -ge 3 ]; then
  echo "rollout history has $count revisions (>= 3)"
else
  echo "rollout history has only ${count:-0} revisions, expected >= 3 (update then rollback)"
  exit 1
fi

echo "All checks passed: webapp is rolled back to nginx:1.28"
