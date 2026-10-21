#!/bin/bash
# T02 Part B: --etcd-servers back on etcd's client port, the API server
# static pod Running and kubectl answering.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

K="kubectl --request-timeout=10s"
fail=0

# Check 1: manifest --etcd-servers is one of etcd's --listen-client-urls
want=$(grep -o -- '--listen-client-urls=[^ ]*' /etc/kubernetes/manifests/etcd.yaml 2>/dev/null | cut -d= -f2)
have=$(grep -o -- '--etcd-servers=[^ ]*' /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null | cut -d= -f2)
ok=0
for u in $(echo "$want" | tr ',' ' '); do
  for h in $(echo "$have" | tr ',' ' '); do
    [ "$h" = "$u" ] && ok=1
  done
done
if [ -n "$have" ] && [ "$ok" = "1" ]; then
  echo "PASS 1: kube-apiserver.yaml --etcd-servers=$have matches etcd listen-client-urls ($want)"
else
  echo "FAIL 1: kube-apiserver.yaml --etcd-servers=${have:-missing} is not in etcd --listen-client-urls ($want)"
  fail=1
fi

# Check 2: the API server answers (retry: the static pod needs 10-60s)
up=0
for i in $(seq 1 18); do
  $K get --raw /healthz >/dev/null 2>&1 && { up=1; break; }
  sleep 5
done
if [ "$up" = "1" ]; then
  echo "PASS 2: API server answers /healthz - kubectl works again"
else
  echo "FAIL 2: API server still not answering after 90s"
  fail=1
fi

# Check 3: kube-apiserver static pod is Running with the fixed value
phase=$($K get pods -n kube-system -l component=kube-apiserver -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
cmd=$($K get pods -n kube-system -l component=kube-apiserver -o jsonpath='{.items[0].spec.containers[0].command}' 2>/dev/null)
if [ "$phase" = "Running" ] && [ -n "$have" ] && echo "$cmd" | grep -q -- "--etcd-servers=$have"; then
  echo "PASS 3: kube-apiserver pod is Running with --etcd-servers=$have"
else
  echo "FAIL 3: kube-apiserver pod phase=${phase:-not found}, command carries --etcd-servers=${have:-?}: $(echo "$cmd" | grep -q -- "--etcd-servers=$have" && echo yes || echo no)"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - API server back on the right etcd endpoint"
exit 0
