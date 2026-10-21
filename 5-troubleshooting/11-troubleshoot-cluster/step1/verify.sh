#!/bin/bash
# 11: nodes Ready with the worker kubelet running (Scenario A), cluster
# DNS restored - kube-dns Service selects the CoreDNS pods and has
# endpoints (Scenario B), kube-proxy on every node (Scenario C), audit
# logging present and populated (Scenario D).
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

K="kubectl --request-timeout=10s"
fail=0

# Check 1: every node is Ready (retry: a restarted kubelet needs ~40s)
nodes=""
for i in $(seq 1 12); do
  nodes=$($K get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"="}{.status.conditions[?(@.type=="Ready")].status}{" "}{end}' 2>/dev/null)
  echo "$nodes" | grep -q '=False\|=Unknown' || { [ -n "$nodes" ] && break; }
  sleep 5
done
if [ -n "$nodes" ] && ! echo "$nodes" | grep -q '=False\|=Unknown'; then
  echo "PASS 1: all nodes Ready ($nodes)"
else
  echo "FAIL 1: not every node is Ready (${nodes:-API server not answering})"
  fail=1
fi

# Check 2: kubelet is active on node01
state=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 node01 'systemctl is-active kubelet' 2>/dev/null)
if [ "$state" = "active" ]; then
  echo "PASS 2: kubelet is active on node01"
else
  echo "FAIL 2: kubelet on node01 is ${state:-unreachable}, expected active"
  fail=1
fi

# Check 3: CoreDNS deployment has ready replicas
ready=$($K get deploy coredns -n kube-system -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -ge 1 ]; then
  echo "PASS 3: coredns has $ready ready replica(s)"
else
  echo "FAIL 3: coredns has no ready replicas (readyReplicas=${ready:-0})"
  fail=1
fi

# Check 4: kube-dns Service selects the CoreDNS pods (k8s-app=kube-dns)
sel=$($K get svc kube-dns -n kube-system -o jsonpath='{.spec.selector.k8s-app}' 2>/dev/null)
if [ "$sel" = "kube-dns" ]; then
  echo "PASS 4: kube-dns Service selector is k8s-app=kube-dns"
else
  echo "FAIL 4: kube-dns Service selector is k8s-app=${sel:-missing}, expected kube-dns"
  fail=1
fi

# Check 5: kube-dns Service has endpoints (retry while endpoints sync)
eps=""
for i in $(seq 1 6); do
  eps=$($K get endpointslices -n kube-system -l kubernetes.io/service-name=kube-dns -o jsonpath='{.items[*].endpoints[*].addresses[*]}' 2>/dev/null)
  [ -n "$eps" ] && break
  sleep 5
done
if [ -n "$eps" ]; then
  echo "PASS 5: kube-dns Service has endpoints ($eps)"
else
  echo "FAIL 5: kube-dns Service has no endpoints - DNS traffic has nowhere to go"
  fail=1
fi

# Check 6: kube-proxy runs on every node (DaemonSet ready == desired)
desired=$($K get ds kube-proxy -n kube-system -o jsonpath='{.status.desiredNumberScheduled}' 2>/dev/null)
dsready=$($K get ds kube-proxy -n kube-system -o jsonpath='{.status.numberReady}' 2>/dev/null)
if [ -n "$desired" ] && [ "$desired" = "$dsready" ] && [ "$desired" -ge 1 ]; then
  echo "PASS 6: kube-proxy DaemonSet ready on every node ($dsready/$desired)"
else
  echo "FAIL 6: kube-proxy DaemonSet not ready on every node (${dsready:-0}/${desired:-?})"
  fail=1
fi

# Check 7: API server audit logging is configured and the log has entries
path=$(grep -o -- '--audit-log-path=[^ ]*' /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null | head -1 | cut -d= -f2)
policy=$(grep -o -- '--audit-policy-file=[^ ]*' /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null | head -1 | cut -d= -f2)
if [ -n "$path" ] && [ -n "$policy" ] && [ -s "$path" ]; then
  echo "PASS 7: audit logging on (policy $policy, log $path, $(wc -l < "$path") entries)"
else
  echo "FAIL 7: audit logging not configured or log empty (path=${path:-unset} policy=${policy:-unset})"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - nodes Ready, DNS endpoints back, kube-proxy everywhere, audit log present"
exit 0
