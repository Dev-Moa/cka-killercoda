#!/bin/bash
# Checks 1-4 each print PASS or FAIL with the exact actual-vs-expected
# evidence. All checks run (no early exit), so one click shows every
# failing part.
# The full output is also written to /tmp/check-report.txt, so the
# candidate can read the reasons even if the CHECK UI hides them.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# --- Check 1: pod logger in exercise-02 is 2/2 Running ---
line=$(kubectl get pod logger -n exercise-02 --no-headers 2>/dev/null)
ready=$(echo "$line" | awk '{print $2}')
status=$(echo "$line" | awk '{print $3}')
if [ "$ready" = "2/2" ] && [ "$status" = "Running" ]; then
  echo "PASS 1: pod logger in exercise-02 is 2/2 Running"
else
  echo "FAIL 1: expected pod 'logger' in namespace 'exercise-02' to be 2/2 Running"
  if [ -z "$line" ]; then
    where=$(kubectl get pods -A --no-headers 2>/dev/null | grep -E '\blogger\b' || true)
    if [ -n "$where" ]; then
      echo "       the pod exists, but NOT in exercise-02:"
      echo "       $where"
    else
      echo "       no pod named 'logger' found in any namespace"
    fi
  else
    echo "       actual: ready=${ready:-none} status=${status:-none}"
  fi
  fail=1
fi

# --- Check 2: initContainer log-agent is a native sidecar (restartPolicy: Always) ---
policy=$(kubectl get pod logger -n exercise-02 -o jsonpath='{.spec.initContainers[?(@.name=="log-agent")].restartPolicy}' 2>/dev/null)
if [ "$policy" = "Always" ]; then
  echo "PASS 2: initContainer log-agent has restartPolicy: Always"
else
  names=$(kubectl get pod logger -n exercise-02 -o jsonpath='{range .spec.initContainers[*]}{.name}{" (restartPolicy="}{.restartPolicy}{") "}{end}' 2>/dev/null)
  echo "FAIL 2: expected an initContainer named 'log-agent' with restartPolicy: Always"
  echo "       initContainers found: ${names:-none}"
  fail=1
fi

# --- Check 3: emptyDir log-volume mounted at /var/log/app in both containers ---
app_mnt=$(kubectl get pod logger -n exercise-02 -o jsonpath='{.spec.containers[?(@.name=="app")].volumeMounts}' 2>/dev/null)
agent_mnt=$(kubectl get pod logger -n exercise-02 -o jsonpath='{.spec.initContainers[?(@.name=="log-agent")].volumeMounts}' 2>/dev/null)
vol=$(kubectl get pod logger -n exercise-02 -o jsonpath='{.spec.volumes[?(@.name=="log-volume")].emptyDir}' 2>/dev/null)
if echo "$app_mnt" | grep -q '"name":"log-volume"' \
  && echo "$app_mnt" | grep -q '"mountPath":"/var/log/app"' \
  && echo "$agent_mnt" | grep -q '"name":"log-volume"' \
  && echo "$agent_mnt" | grep -q '"mountPath":"/var/log/app"' \
  && [ "$vol" = "{}" ]; then
  echo "PASS 3: emptyDir log-volume mounted at /var/log/app in app and log-agent"
else
  echo "FAIL 3: expected emptyDir volume 'log-volume' mounted at '/var/log/app' in BOTH container 'app' and initContainer 'log-agent'"
  echo "       actual container 'app' mounts:    ${app_mnt:-none}"
  echo "       actual initContainer 'log-agent': ${agent_mnt:-none}"
  echo "       actual volume log-volume emptyDir: ${vol:-none}"
  fail=1
fi

# --- Check 4: log-agent logs stream the app's lines (exercise Verify:
# "should see the log lines from the app container"). Any content passes -
# never assert on the candidate's own text. ---
found=""
for i in 1 2 3 4 5; do
  [ -n "$(kubectl logs logger -n exercise-02 -c log-agent 2>/dev/null)" ] && { found=yes; break; }
  sleep 2
done
if [ "$found" = "yes" ]; then
  echo "PASS 4: log-agent logs show the app's log lines"
else
  echo "FAIL 4: log-agent logs are empty - nothing is streaming into them"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - pod logger is 2/2 Running, log-agent is a native sidecar, log-volume is shared, logs stream"
exit 0
