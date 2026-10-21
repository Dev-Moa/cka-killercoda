#!/bin/bash
# 31: Argo CD installed in namespace argocd (server Available, the
# Application CRD present), an Application resource (name not fixed by
# the task) with repoURL, path and destination namespace, sync status
# Synced, and workloads present in the destination namespace.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# Check 1: namespace argocd exists
if kubectl get ns argocd >/dev/null 2>&1; then
  echo "PASS 1: namespace argocd exists"
else
  echo "FAIL 1: namespace argocd not found"
  fail=1
fi

# Check 2: argocd-server deployment is Available (retry: images take a while)
avail=""
for _ in $(seq 1 12); do
  avail=$(kubectl get deploy argocd-server -n argocd -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)
  [ "$avail" = "True" ] && break
  sleep 10
done
if [ "$avail" = "True" ]; then
  echo "PASS 2: deployment argocd-server in argocd is Available"
else
  echo "FAIL 2: deployment argocd-server in argocd not Available (status=${avail:-not found})"
  fail=1
fi

# Check 3: the Application CRD was installed by the Argo CD manifests
if kubectl get crd applications.argoproj.io >/dev/null 2>&1; then
  echo "PASS 3: CRD applications.argoproj.io exists"
else
  echo "FAIL 3: CRD applications.argoproj.io not found - Argo CD manifests not applied"
  fail=1
fi

# Check 4: an Application in argocd with repoURL, path and destination namespace
app=$(kubectl get applications.argoproj.io -n argocd -o jsonpath='{range .items[*]}{.metadata.name}{"|"}{.spec.source.repoURL}{"|"}{.spec.source.path}{"|"}{.spec.destination.namespace}{"\n"}{end}' 2>/dev/null \
  | awk -F'|' '$2!="" && $3!="" && $4!="" {print; exit}')
IFS='|' read -r name repo path dest <<< "$app"
if [ -n "$name" ]; then
  echo "PASS 4: Application $name points at $repo path $path, destination namespace $dest"
else
  names=$(kubectl get applications.argoproj.io -n argocd -o name 2>/dev/null | tr '\n' ' ')
  echo "FAIL 4: no Application in argocd with spec.source.repoURL, spec.source.path and spec.destination.namespace all set (found: ${names:-none})"
  fail=1
fi

# Check 5: that Application's sync status is Synced (retry: the first sync takes a minute)
sync=""
if [ -n "$name" ]; then
  for _ in $(seq 1 12); do
    sync=$(kubectl get applications.argoproj.io "$name" -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null)
    [ "$sync" = "Synced" ] && break
    sleep 10
  done
fi
if [ "$sync" = "Synced" ]; then
  echo "PASS 5: Application $name sync status is Synced"
else
  echo "FAIL 5: Application ${name:-?} sync status is '${sync:-unknown}', expected Synced (check repoURL/path, and sync it if the policy is manual)"
  fail=1
fi

# Check 6: the destination namespace holds what Argo CD deployed (a Deployment or Service)
objs=$(kubectl get deployment,service -n "${dest:-default}" -o name 2>/dev/null | grep -v '^service/kubernetes$' | grep -c .)
if [ "${objs:-0}" -ge 1 ]; then
  echo "PASS 6: namespace ${dest:-default} has $objs deployment/service object(s) from the sync"
else
  echo "FAIL 6: namespace ${dest:-default} has no Deployment or Service - nothing was deployed by the Application"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - Argo CD running, Application Synced, workloads deployed"
exit 0
