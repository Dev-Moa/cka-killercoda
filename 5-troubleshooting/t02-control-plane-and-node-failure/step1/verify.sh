#!/bin/bash
# T02 Part A: the scheduler manifest runs "kube-scheduler" again, the
# scheduler static pod is Running, and the 2 test pods got scheduled.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

K="kubectl --request-timeout=10s"
fail=0

# Check 1: the manifest's command is kube-scheduler (typo removed)
if grep -qE '^\s+- kube-scheduler$' /etc/kubernetes/manifests/kube-scheduler.yaml 2>/dev/null; then
  echo "PASS 1: kube-scheduler.yaml command entry is kube-scheduler"
else
  bad=$(grep -E '^\s+- kube-scheduler' /etc/kubernetes/manifests/kube-scheduler.yaml 2>/dev/null | head -1 | sed 's/^ *//')
  echo "FAIL 1: kube-scheduler.yaml command entry is '${bad:-missing}', expected '- kube-scheduler'"
  fail=1
fi

# Check 2: the scheduler static pod is Running (name kube-scheduler*-controlplane;
# retry while the kubelet restarts it)
sched=""
for i in $(seq 1 12); do
  sched=$($K get pods -n kube-system -o jsonpath='{range .items[*]}{.metadata.name}{"="}{.status.phase}{"/"}{.status.containerStatuses[0].ready}{" "}{end}' 2>/dev/null \
    | tr ' ' '\n' | grep '^kube-scheduler.*-controlplane=' | head -1)
  echo "$sched" | grep -q '=Running/true$' && break
  sleep 5
done
if echo "$sched" | grep -q '=Running/true$'; then
  echo "PASS 2: scheduler pod ${sched%%=*} is Running and ready"
else
  echo "FAIL 2: scheduler pod not Running/ready (${sched:-no kube-scheduler pod on controlplane})"
  fail=1
fi

# Check 3: deployment test has 2 ready replicas (pods were scheduled)
ready=""
for i in $(seq 1 12); do
  ready=$($K get deploy test -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  [ "$ready" = "2" ] && break
  sleep 5
done
if [ "$ready" = "2" ]; then
  echo "PASS 3: deployment test has 2 ready replicas"
else
  pend=$($K get pods -l app=test -o jsonpath='{range .items[*]}{.metadata.name}{"="}{.status.phase}{" "}{end}' 2>/dev/null)
  echo "FAIL 3: deployment test readyReplicas=${ready:-0}, expected 2 (pods: ${pend:-none})"
  fail=1
fi

# Check 4: every test pod has a node assigned
unsched=$($K get pods -l app=test -o jsonpath='{range .items[*]}{.metadata.name}{"="}{.spec.nodeName}{" "}{end}' 2>/dev/null | tr ' ' '\n' | grep -c '=$')
if [ -n "$ready" ] && [ "${unsched:-0}" = "0" ]; then
  echo "PASS 4: every test pod is bound to a node"
else
  echo "FAIL 4: ${unsched:-?} test pod(s) still have no node"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - scheduler fixed, test pods scheduled"
exit 0
