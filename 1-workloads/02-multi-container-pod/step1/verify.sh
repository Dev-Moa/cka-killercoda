#!/bin/bash
# All checks in the order of the question's verification list.
# Each check prints a one-line pass or failure reason and exit 1 on the
# first failure; after all checks pass, print one overall success line.

# Check 1: pod logger in exercise-02 is Running with 2/2 ready
line=$(kubectl get pod logger -n exercise-02 --no-headers 2>/dev/null)
ready=$(echo "$line" | awk '{print $2}')
status=$(echo "$line" | awk '{print $3}')
if [ "$ready" = "2/2" ] && [ "$status" = "Running" ]; then
  echo "pod logger is Running with 2/2 containers ready"
else
  echo "pod logger not 2/2 Running (ready=${ready:-none}, status=${status:-not found})"
  exit 1
fi

# Check 2: initContainer log-agent is a native sidecar (restartPolicy: Always)
policy=$(kubectl get pod logger -n exercise-02 -o jsonpath='{.spec.initContainers[?(@.name=="log-agent")].restartPolicy}' 2>/dev/null)
if [ "$policy" = "Always" ]; then
  echo "initContainer log-agent is a native sidecar (restartPolicy: Always)"
else
  echo "initContainer log-agent with restartPolicy: Always not found (got: ${policy:-none})"
  exit 1
fi

# Check 3: emptyDir log-volume mounted at /var/log/app in both containers
app_mnt=$(kubectl get pod logger -n exercise-02 -o jsonpath='{.spec.containers[?(@.name=="app")].volumeMounts}' 2>/dev/null)
agent_mnt=$(kubectl get pod logger -n exercise-02 -o jsonpath='{.spec.initContainers[?(@.name=="log-agent")].volumeMounts}' 2>/dev/null)
vol=$(kubectl get pod logger -n exercise-02 -o jsonpath='{.spec.volumes[?(@.name=="log-volume")].emptyDir}' 2>/dev/null)
if echo "$app_mnt" | grep -q '"name":"log-volume"' \
  && echo "$app_mnt" | grep -q '"mountPath":"/var/log/app"' \
  && echo "$agent_mnt" | grep -q '"name":"log-volume"' \
  && echo "$agent_mnt" | grep -q '"mountPath":"/var/log/app"' \
  && [ "$vol" = "{}" ]; then
  echo "emptyDir log-volume mounted at /var/log/app in both containers"
else
  echo "log-volume mount check failed (app or log-agent missing the /var/log/app mount, or volume not emptyDir)"
  exit 1
fi

# Check 4: log-agent logs contain 'app running' (app writes every 3s, so retry)
found=""
for i in 1 2 3 4 5; do
  kubectl logs logger -n exercise-02 -c log-agent 2>/dev/null | grep -q "app running" && { found=yes; break; }
  sleep 2
done
if [ "$found" = "yes" ]; then
  echo "log-agent logs contain 'app running'"
else
  echo "log-agent logs do not contain 'app running'"
  exit 1
fi

echo "All checks passed: pod logger is 2/2 Running, log-agent is a native sidecar, log-volume is shared, logs stream"
exit 0
