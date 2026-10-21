#!/bin/bash
# T02 Part C: kubelet active on node01 and node01 Ready again; the
# control plane from Parts A and B still healthy.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

K="kubectl --request-timeout=10s"
fail=0

# Check 1: kubelet is active on node01
state=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 node01 'systemctl is-active kubelet' 2>/dev/null)
if [ "$state" = "active" ]; then
  echo "PASS 1: kubelet is active on node01"
else
  echo "FAIL 1: kubelet on node01 is ${state:-unreachable}, expected active"
  fail=1
fi

# Check 2: node01 is Ready (retry: a restarted kubelet needs up to ~40s)
ready=""
for i in $(seq 1 12); do
  ready=$($K get node node01 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
  [ "$ready" = "True" ] && break
  sleep 5
done
if [ "$ready" = "True" ]; then
  echo "PASS 2: node01 is Ready"
else
  echo "FAIL 2: node01 not Ready (Ready=${ready:-unknown})"
  fail=1
fi

# Check 3: every node is Ready
nodes=$($K get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"="}{.status.conditions[?(@.type=="Ready")].status}{" "}{end}' 2>/dev/null)
if [ -n "$nodes" ] && ! echo "$nodes" | grep -q '=False\|=Unknown'; then
  echo "PASS 3: all nodes Ready ($nodes)"
else
  echo "FAIL 3: not every node is Ready (${nodes:-API server not answering})"
  fail=1
fi

# Check 4: scheduler and API server static pods are Running (Parts A and B hold)
cp=$($K get pods -n kube-system -o jsonpath='{range .items[*]}{.metadata.name}{"="}{.status.phase}{" "}{end}' 2>/dev/null \
  | tr ' ' '\n' | grep -E '^kube-(scheduler.*|apiserver)-controlplane=' | tr '\n' ' ')
if echo "$cp" | grep -q 'kube-scheduler.*=Running' && echo "$cp" | grep -q 'kube-apiserver-controlplane=Running'; then
  echo "PASS 4: control plane static pods Running ($cp)"
else
  echo "FAIL 4: scheduler or API server pod not Running (${cp:-none found})"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - node01 Ready, control plane healthy"
exit 0
