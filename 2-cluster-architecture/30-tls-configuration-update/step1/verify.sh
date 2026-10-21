#!/bin/bash
# 30: ConfigMap lists both TLS versions, deployment ready, service
# answers TLS 1.2 and TLS 1.3 handshakes.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

NS=exercise-30
fail=0

# Check 1: ConfigMap tls-server-config mentions both TLS 1.2 and 1.3
data=$(kubectl -n "$NS" get cm tls-server-config -o jsonpath='{.data}' 2>/dev/null)
if echo "$data" | grep -qi 'TLSv1\.2' && echo "$data" | grep -qi 'TLSv1\.3'; then
  echo "PASS 1: ConfigMap tls-server-config lists TLS 1.2 and TLS 1.3"
else
  echo "FAIL 1: ConfigMap tls-server-config must list both TLS 1.2 and TLS 1.3 (got data=${data:-not found})"
  fail=1
fi

# Check 2: deployment tls-server is fully ready
ready=$(kubectl -n "$NS" get deployment tls-server -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
repl=$(kubectl -n "$NS" get deployment tls-server -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ -n "$ready" ] && [ "$ready" = "$repl" ]; then
  echo "PASS 2: deployment tls-server ready ($ready/$repl)"
else
  echo "FAIL 2: deployment tls-server not ready (ready=${ready:-0}/${repl:-not found})"
  fail=1
fi

# Check 3: the tls-server pod is Running
phase=$(kubectl -n "$NS" get pod -l app=tls-server -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
if [ "$phase" = "Running" ]; then
  echo "PASS 3: pod tls-server is Running"
else
  echo "FAIL 3: pod tls-server not Running (phase=${phase:-not found})"
  fail=1
fi

# Check 4: service tls-server has at least one endpoint
ep=$(kubectl -n "$NS" get endpoints tls-server -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
if [ -n "$ep" ]; then
  echo "PASS 4: service tls-server has endpoints"
else
  echo "FAIL 4: service tls-server has no endpoints"
  fail=1
fi

ip=$(kubectl -n "$NS" get svc tls-server -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
port=$(kubectl -n "$NS" get svc tls-server -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)

# Check 5: service accepts TLS 1.2 (retry while pods settle after restart)
handshake=""
for i in 1 2 3 4 5 6; do
  handshake=$(echo | timeout 10 openssl s_client -connect "${ip}:${port}" -tls1_2 2>/dev/null | grep '^New, TLSv1')
  echo "$handshake" | grep -q 'TLSv1\.2' && break
  sleep 5
done
if echo "$handshake" | grep -q 'TLSv1\.2'; then
  echo "PASS 5: service negotiates TLS 1.2 ($handshake)"
else
  echo "FAIL 5: service does not accept TLS 1.2 (got ${handshake:-no handshake} on ${ip}:${port})"
  fail=1
fi

# Check 6: service still accepts TLS 1.3
handshake=""
for i in 1 2 3; do
  handshake=$(echo | timeout 10 openssl s_client -connect "${ip}:${port}" -tls1_3 2>/dev/null | grep '^New, TLSv1')
  echo "$handshake" | grep -q 'TLSv1\.3' && break
  sleep 5
done
if echo "$handshake" | grep -q 'TLSv1\.3'; then
  echo "PASS 6: service negotiates TLS 1.3 ($handshake)"
else
  echo "FAIL 6: service does not accept TLS 1.3 (got ${handshake:-no handshake} on ${ip}:${port})"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - TLS 1.2 and 1.3 both work, ConfigMap updated, deployment ready"
exit 0
