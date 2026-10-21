#!/bin/bash
# 27-cni-tigera-install: tigera-operator Deployment available,
# Installation resource with an ipPool CIDR equal to the cluster pod
# CIDR, calico-node pods Running in calico-system. Tolerant of the
# playground state: pod-network checks (tasks 6-7) are not graded.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# Check 1: tigera-operator Deployment is Available
avail=$(kubectl get deploy tigera-operator -n tigera-operator -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)
if [ "$avail" = "True" ]; then
  echo "PASS 1: deployment tigera-operator in tigera-operator is Available"
else
  echo "FAIL 1: deployment tigera-operator in tigera-operator not Available (status=${avail:-not found})"
  fail=1
fi

# Check 2: an Installation resource exists (operator.tigera.io)
inst=$(kubectl get installations.operator.tigera.io -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$inst" ]; then
  echo "PASS 2: Installation resource '$inst' exists"
else
  echo "FAIL 2: no Installation resource found (kubectl get installations.operator.tigera.io)"
  fail=1
fi

# Check 3: an ipPool CIDR in the Installation equals the cluster pod CIDR
cluster_cidr=$(kubectl get cm kubeadm-config -n kube-system -o jsonpath='{.data.ClusterConfiguration}' 2>/dev/null | sed -n 's/^ *podSubnet: *//p' | head -1)
[ -z "$cluster_cidr" ] && cluster_cidr=$(kubectl get pod -n kube-system -l component=kube-controller-manager -o jsonpath='{.items[0].spec.containers[0].command}' 2>/dev/null | grep -o -- '--cluster-cidr=[^"]*' | cut -d= -f2)
pools=$(kubectl get installations.operator.tigera.io "$inst" -o jsonpath='{.spec.calicoNetwork.ipPools[*].cidr}' 2>/dev/null)
if [ -n "$cluster_cidr" ] && echo " $pools " | grep -q " $cluster_cidr "; then
  echo "PASS 3: Installation ipPool CIDR $cluster_cidr matches the cluster pod CIDR"
else
  echo "FAIL 3: Installation ipPools (${pools:-none}) do not include the cluster pod CIDR (${cluster_cidr:-unknown})"
  fail=1
fi

# Check 4: calico-node pods Running in calico-system (retry: install takes minutes)
running=0
for _ in 1 2 3 4 5 6; do
  running=$(kubectl get pods -n calico-system -l k8s-app=calico-node -o jsonpath='{.items[*].status.phase}' 2>/dev/null | tr ' ' '\n' | grep -c '^Running$')
  [ "$running" -ge 1 ] && break
  sleep 10
done
if [ "$running" -ge 1 ]; then
  echo "PASS 4: $running calico-node pod(s) Running in calico-system"
else
  echo "FAIL 4: no calico-node pod Running in calico-system (kubectl get pods -n calico-system)"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - operator available, Installation CIDR matches, calico-node running"
exit 0
