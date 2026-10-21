#!/bin/bash
# T04: Metrics Server Running, kubectl top node returns rows, deployment
# load (nginx) is Running in default and kubectl top pod shows its pod.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# Check 1: metrics-server deployment has a ready replica in kube-system
ready=$(kubectl get deploy metrics-server -n kube-system -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -ge 1 ]; then
  echo "PASS 1: metrics-server has $ready ready replica(s) in kube-system"
else
  echo "FAIL 1: metrics-server not ready in kube-system (readyReplicas=${ready:-0})"
  fail=1
fi

# Check 2: kubectl top node returns one row per node (retry: first scrape takes ~1 min)
rows=0
nodes=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
for i in $(seq 1 12); do
  rows=$(kubectl top nodes --no-headers 2>/dev/null | grep -c .)
  [ "$rows" -ge 1 ] && [ "$rows" -ge "$nodes" ] && break
  sleep 5
done
if [ "$rows" -ge 1 ]; then
  echo "PASS 2: kubectl top node returns $rows row(s) for $nodes node(s)"
else
  echo "FAIL 2: kubectl top node returns no rows yet (metrics not available)"
  fail=1
fi

# Check 3: deployment load exists in default with image nginx and a ready replica
image=$(kubectl get deploy load -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
lready=$(kubectl get deploy load -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
case "$image" in nginx*) img_ok=1 ;; *) img_ok=0 ;; esac
if [ "$img_ok" = "1" ] && [ "${lready:-0}" -ge 1 ]; then
  echo "PASS 3: deployment load is Running with image $image"
else
  echo "FAIL 3: deployment load expected image nginx with a ready replica (image=${image:-missing} readyReplicas=${lready:-0})"
  fail=1
fi

# Check 4: kubectl top pod shows the load pod (retry: a new pod needs a scrape)
pod=$(kubectl get pods -l app=load -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
[ -n "$pod" ] || pod=$(kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null | grep '^load-' | head -1)
row=""
for i in $(seq 1 12); do
  row=$(kubectl top pod --no-headers 2>/dev/null | grep "^${pod:-load-}")
  [ -n "$row" ] && break
  sleep 5
done
if [ -n "$row" ]; then
  echo "PASS 4: kubectl top pod shows the load pod ($row)"
else
  echo "FAIL 4: kubectl top pod has no row for the load pod (${pod:-no load pod found})"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - Metrics Server up, node and pod metrics readable"
exit 0
