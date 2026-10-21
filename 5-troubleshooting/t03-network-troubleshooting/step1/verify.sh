#!/bin/bash
# T03: hostnames pods healthy, Service targetPort fixed with three
# endpoints on 9376 and answering on its ClusterIP, CoreDNS back with
# kube-dns endpoints, kube-proxy on every node.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# Check 1: deployment hostnames has 3 ready replicas
ready=$(kubectl get deploy hostnames -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$ready" = "3" ]; then
  echo "PASS 1: deployment hostnames has 3 ready replicas"
else
  echo "FAIL 1: deployment hostnames readyReplicas=${ready:-0}, expected 3"
  fail=1
fi

# Check 2: Service hostnames targets port 9376 (the port the app listens on)
tp=$(kubectl get svc hostnames -o jsonpath='{.spec.ports[0].targetPort}' 2>/dev/null)
if [ "$tp" = "9376" ]; then
  echo "PASS 2: Service hostnames targetPort is 9376"
else
  echo "FAIL 2: Service hostnames targetPort is ${tp:-missing}, expected 9376"
  fail=1
fi

# Check 3: Service hostnames has three endpoints on port 9376 (retry while syncing)
n=0
for i in $(seq 1 6); do
  rows=$(kubectl get endpointslices -l kubernetes.io/service-name=hostnames -o jsonpath='{range .items[*]}{.ports[0].port}{"="}{.endpoints[*].addresses[*]}{"\n"}{end}' 2>/dev/null)
  n=$(echo "$rows" | grep '^9376=' | tr ' ' '\n' | grep -c '[0-9]')
  [ "$n" -ge 3 ] && break
  sleep 3
done
if [ "$n" -ge 3 ]; then
  echo "PASS 3: Service hostnames has $n endpoints on port 9376"
else
  echo "FAIL 3: expected 3 endpoints on port 9376 for Service hostnames (got: ${rows:-none})"
  fail=1
fi

# Check 4: the Service answers on its ClusterIP (tested from controlplane)
ip=$(kubectl get svc hostnames -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
port=$(kubectl get svc hostnames -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
body=""
for i in $(seq 1 5); do
  body=$(curl -s --max-time 5 "http://${ip}:${port}/" 2>/dev/null)
  [ -n "$body" ] && break
  sleep 3
done
if [ -n "$body" ]; then
  echo "PASS 4: Service hostnames answers on ${ip}:${port} (a pod hostname came back)"
else
  echo "FAIL 4: nothing answers on ${ip:-?}:${port:-?} - Service to pod path still broken"
  fail=1
fi

# Check 5: CoreDNS is back (deployment scaled up with ready replicas)
cready=$(kubectl get deploy coredns -n kube-system -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${cready:-0}" -ge 1 ]; then
  echo "PASS 5: coredns has $cready ready replica(s)"
else
  spec=$(kubectl get deploy coredns -n kube-system -o jsonpath='{.spec.replicas}' 2>/dev/null)
  echo "FAIL 5: coredns has no ready replicas (spec.replicas=${spec:-?})"
  fail=1
fi

# Check 6: kube-dns Service has endpoints (DNS traffic has somewhere to go)
eps=""
for i in $(seq 1 6); do
  eps=$(kubectl get endpointslices -n kube-system -l kubernetes.io/service-name=kube-dns -o jsonpath='{.items[*].endpoints[*].addresses[*]}' 2>/dev/null)
  [ -n "$eps" ] && break
  sleep 5
done
if [ -n "$eps" ]; then
  echo "PASS 6: kube-dns Service has endpoints ($eps)"
else
  echo "FAIL 6: kube-dns Service has no endpoints"
  fail=1
fi

# Check 7: kube-proxy runs on every node (DaemonSet ready == desired)
desired=$(kubectl get ds kube-proxy -n kube-system -o jsonpath='{.status.desiredNumberScheduled}' 2>/dev/null)
dsready=$(kubectl get ds kube-proxy -n kube-system -o jsonpath='{.status.numberReady}' 2>/dev/null)
if [ -n "$desired" ] && [ "$desired" = "$dsready" ] && [ "$desired" -ge 1 ]; then
  echo "PASS 7: kube-proxy DaemonSet ready on every node ($dsready/$desired)"
else
  echo "FAIL 7: kube-proxy DaemonSet not ready on every node (${dsready:-0}/${desired:-?})"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - Service endpoints on 9376, CoreDNS back, kube-proxy everywhere"
exit 0
