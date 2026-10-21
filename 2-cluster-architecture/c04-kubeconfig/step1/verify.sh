#!/bin/bash
# C04: /tmp/my-kube-config exists and works, its server port is back on
# 6443, its current context defaults to kube-system, and the original
# default kubeconfig current-context is untouched.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# Check 1: the custom file exists and its server points to port 6443
server=$(kubectl --kubeconfig /tmp/my-kube-config config view --minify \
  -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null)
if [ -n "$server" ] && [ "${server##*:}" = "6443" ]; then
  echo "PASS 1: /tmp/my-kube-config server is $server"
else
  echo "FAIL 1: /tmp/my-kube-config server must end in :6443 (got ${server:-file missing or unreadable})"
  fail=1
fi

# Check 2: the custom file can list the nodes (port fixed, certs valid)
nodes=$(kubectl --kubeconfig /tmp/my-kube-config get nodes \
  --no-headers 2>/dev/null | wc -l)
if [ "${nodes:-0}" -ge 1 ]; then
  echo "PASS 2: kubectl --kubeconfig /tmp/my-kube-config get nodes returns $nodes node(s)"
else
  echo "FAIL 2: get nodes with the custom file returned no nodes (got ${nodes:-0})"
  fail=1
fi

# Check 3: the current context of the custom file defaults to kube-system
ns=$(kubectl --kubeconfig /tmp/my-kube-config config view --minify \
  -o jsonpath='{.contexts[0].context.namespace}' 2>/dev/null)
if [ "$ns" = "kube-system" ]; then
  echo "PASS 3: custom file current context namespace is kube-system"
else
  echo "FAIL 3: custom file current context namespace expected kube-system (got ${ns:-none set})"
  fail=1
fi

# Check 4: the default kubeconfig current-context is untouched
original=$(cat /tmp/exam/original-context.txt 2>/dev/null)
current=$(kubectl config current-context 2>/dev/null)
if [ "$current" = "$original" ]; then
  echo "PASS 4: default kubeconfig current-context is still $current"
else
  echo "FAIL 4: default current-context changed (was ${original:-unknown}, now ${current:-none})"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - custom kubeconfig works on 6443, defaults to kube-system, default config untouched"
exit 0
