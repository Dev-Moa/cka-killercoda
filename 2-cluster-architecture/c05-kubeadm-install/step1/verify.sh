#!/bin/bash
# C05: cluster rebuilt with kubeadm - both nodes Ready (roles control-plane
# and <none>), pod CIDR inside 10.244.0.0/16, one Running Flannel pod per
# node, and the test pod web Running with the nginx image.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# Check 1: controlplane is Ready and keeps the control-plane role
ready=$(kubectl get node controlplane -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
labels=$(kubectl get node controlplane -o jsonpath='{.metadata.labels}' 2>/dev/null)
if [ "$ready" = "True" ] && printf '%s' "$labels" | grep -q 'control-plane'; then
  echo "PASS 1: controlplane is Ready (role control-plane)"
else
  echo "FAIL 1: controlplane not Ready or missing control-plane role (ready=${ready:-no node}, labels=${labels:-none})"
  fail=1
fi

# Check 2: node01 has joined, is Ready, and has no control-plane role
ready=$(kubectl get node node01 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
labels=$(kubectl get node node01 -o jsonpath='{.metadata.labels}' 2>/dev/null)
if [ "$ready" = "True" ] && ! printf '%s' "$labels" | grep -q 'control-plane'; then
  echo "PASS 2: node01 is Ready (worker role)"
else
  echo "FAIL 2: node01 not Ready or has control-plane role (ready=${ready:-no node}, labels=${labels:-none})"
  fail=1
fi

# Check 3: kubeadm init used --pod-network-cidr 10.244.0.0/16
cidr=$(kubectl get node controlplane -o jsonpath='{.spec.podCIDR}' 2>/dev/null)
case "$cidr" in
  10.244.*)
    echo "PASS 3: controlplane podCIDR $cidr is inside 10.244.0.0/16"
    ;;
  *)
    echo "FAIL 3: controlplane podCIDR not inside 10.244.0.0/16 (got ${cidr:-none})"
    fail=1
    ;;
esac

# Check 4: one Running Flannel pod per node (namespace kube-flannel)
flannel_nodes=$(kubectl get pods -n kube-flannel --field-selector=status.phase=Running -o jsonpath='{.items[*].spec.nodeName}' 2>/dev/null)
count=$(printf '%s' "$flannel_nodes" | wc -w)
has_cp=$(printf '%s' "$flannel_nodes" | grep -c controlplane)
has_w=$(printf '%s' "$flannel_nodes" | grep -c node01)
if [ "$count" = "2" ] && [ "$has_cp" = "1" ] && [ "$has_w" = "1" ]; then
  echo "PASS 4: one Running Flannel pod on each node (controlplane, node01)"
else
  echo "FAIL 4: expected one Running Flannel pod per node (got ${count:-0} pods on nodes: ${flannel_nodes:-none})"
  fail=1
fi

# Check 5: test pod web is Running with the nginx image
phase=$(kubectl get pod web -o jsonpath='{.status.phase}' 2>/dev/null)
image=$(kubectl get pod web -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)
if [ "$phase" = "Running" ] && printf '%s' "$image" | grep -q '^nginx'; then
  echo "PASS 5: pod web is Running (image $image)"
else
  echo "FAIL 5: pod web not Running with nginx image (phase=${phase:-no pod}, image=${image:-none})"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - two Ready nodes, Flannel on both, web pod Running"
exit 0
