#!/bin/bash
# 09: kubeadm upgrade — both nodes Ready and uncordoned on a newer,
# matching kubelet version. Evidence-only output, also written to
# /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

initial=$(cat /tmp/exam/initial-version.txt 2>/dev/null)
cp_ver=$(kubectl get node controlplane -o jsonpath='{.status.nodeInfo.kubeletVersion}' 2>/dev/null)
w_ver=$(kubectl get node node01 -o jsonpath='{.status.nodeInfo.kubeletVersion}' 2>/dev/null)
cp_ready=$(kubectl get node controlplane -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
w_ready=$(kubectl get node node01 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
w_cordoned=$(kubectl get node node01 -o jsonpath='{.spec.unschedulable}' 2>/dev/null)

# newer_than CUR OLD: true (exit 0) when CUR is a newer v-prefixed version
newer_than() {
  [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n1)" = "$1" ]
}

# Check 1: background.sh recorded the pre-upgrade version
if [ -n "$initial" ]; then
  echo "PASS 1: initial version recorded (initial=$initial)"
else
  echo "FAIL 1: initial version not recorded (expected /tmp/exam/initial-version.txt)"
  fail=1
fi

# Check 2: node controlplane is Ready
if [ "$cp_ready" = "True" ]; then
  echo "PASS 2: node controlplane is Ready"
else
  echo "FAIL 2: node controlplane not Ready (ready=${cp_ready:-not found})"
  fail=1
fi

# Check 3: node node01 is Ready
if [ "$w_ready" = "True" ]; then
  echo "PASS 3: node node01 is Ready"
else
  echo "FAIL 3: node node01 not Ready (ready=${w_ready:-not found})"
  fail=1
fi

# Check 4: node01 is uncordoned (spec.unschedulable is empty)
if [ -z "$w_cordoned" ]; then
  echo "PASS 4: node node01 is schedulable (uncordoned)"
else
  echo "FAIL 4: node node01 is cordoned (spec.unschedulable=$w_cordoned)"
  fail=1
fi

# Check 5: controlplane kubelet runs a newer version than at the start
if [ -n "$initial" ] && [ -n "$cp_ver" ] && newer_than "$cp_ver" "$initial"; then
  echo "PASS 5: controlplane kubelet upgraded (initial=$initial now=$cp_ver)"
else
  echo "FAIL 5: controlplane kubelet not upgraded (initial=$initial now=${cp_ver:-not found})"
  fail=1
fi

# Check 6: node01 kubelet runs a newer version than at the start
if [ -n "$initial" ] && [ -n "$w_ver" ] && newer_than "$w_ver" "$initial"; then
  echo "PASS 6: node01 kubelet upgraded (initial=$initial now=$w_ver)"
else
  echo "FAIL 6: node01 kubelet not upgraded (initial=$initial now=${w_ver:-not found})"
  fail=1
fi

# Check 7: both nodes report the same kubelet version
if [ -n "$cp_ver" ] && [ -n "$w_ver" ] && [ "$cp_ver" = "$w_ver" ]; then
  echo "PASS 7: both nodes on the same kubelet version ($cp_ver)"
else
  echo "FAIL 7: node versions differ (controlplane=${cp_ver:-not found} node01=${w_ver:-not found})"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - all nodes upgraded to $cp_ver and Ready, node01 uncordoned"
exit 0
