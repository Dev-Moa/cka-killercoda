#!/bin/bash
# Merged validators q3_s1..q3_s4 in verification order:
# ConfigMap, Secret, pod env vars, ConfigMap mount.
# Exit 1 on the first failed check; all pass -> one success line.

# 1. ConfigMap app-config has APP_MODE=production and LOG_LEVEL=debug
mode=$(kubectl get configmap app-config -n exercise-03 -o jsonpath='{.data.APP_MODE}' 2>/dev/null)
level=$(kubectl get configmap app-config -n exercise-03 -o jsonpath='{.data.LOG_LEVEL}' 2>/dev/null)
if [ "$mode" = "production" ] && [ "$level" = "debug" ]; then
  echo "configmap app-config has APP_MODE=production and LOG_LEVEL=debug"
else
  echo "configmap app-config wrong (APP_MODE=${mode:-missing}, LOG_LEVEL=${level:-missing})"
  exit 1
fi

# 2. Secret db-creds has DB_USER=admin and DB_PASS=s3cretP@ss
user=$(kubectl get secret db-creds -n exercise-03 -o jsonpath='{.data.DB_USER}' 2>/dev/null | base64 -d)
pass=$(kubectl get secret db-creds -n exercise-03 -o jsonpath='{.data.DB_PASS}' 2>/dev/null | base64 -d)
if [ "$user" = "admin" ] && [ "$pass" = "s3cretP@ss" ]; then
  echo "secret db-creds has DB_USER=admin and DB_PASS=s3cretP@ss"
else
  echo "secret db-creds wrong (DB_USER=${user:-missing}, DB_PASS=${pass:-missing})"
  exit 1
fi

# 3. pod app is Running and its env has APP_MODE, LOG_LEVEL, DB_USER, DB_PASS
phase=$(kubectl get pod app -n exercise-03 -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$phase" != "Running" ]; then
  echo "pod app not Running in exercise-03 (phase: ${phase:-not found})"
  exit 1
fi
env=$(kubectl exec app -n exercise-03 -- env 2>/dev/null)
if echo "$env" | grep -q '^APP_MODE=production$' \
  && echo "$env" | grep -q '^LOG_LEVEL=debug$' \
  && echo "$env" | grep -q '^DB_USER=admin$' \
  && echo "$env" | grep -q '^DB_PASS=s3cretP@ss$'; then
  echo "pod app env has APP_MODE=production, LOG_LEVEL=debug, DB_USER=admin, DB_PASS=s3cretP@ss"
else
  echo "pod app env is missing one or more of APP_MODE/LOG_LEVEL/DB_USER/DB_PASS"
  exit 1
fi

# 4. /etc/config mounted from the ConfigMap and APP_MODE file reads production
srcs=$(kubectl get pod app -n exercise-03 -o jsonpath='{.spec.volumes[*].configMap.name}' 2>/dev/null)
paths=$(kubectl get pod app -n exercise-03 -o jsonpath='{.spec.containers[*].volumeMounts[*].mountPath}' 2>/dev/null)
out=$(kubectl exec app -n exercise-03 -- cat /etc/config/APP_MODE 2>/dev/null)
if echo " $srcs " | grep -q ' app-config ' \
  && echo "$paths" | grep -q '/etc/config' \
  && [ "$out" = "production" ]; then
  echo "/etc/config mounted from ConfigMap app-config and APP_MODE file reads 'production'"
else
  echo "/etc/config mount check failed (configMap volumes=${srcs:-none}, mountPaths=${paths:-none}, APP_MODE file='${out:-empty}')"
  exit 1
fi

echo "All checks passed: ConfigMap, Secret, pod env and /etc/config mount"
