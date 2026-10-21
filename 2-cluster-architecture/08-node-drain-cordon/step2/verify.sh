#!/bin/bash
# 08 step 2: node01 uncordoned, the candidate's Deployment (any name)
# scaled to 6 and spread across both nodes.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# Check 1: node01 is uncordoned again
unsched=$(kubectl get node node01 -o jsonpath='{.spec.unschedulable}' 2>/dev/null)
if [ "$unsched" = "true" ]; then
  echo "FAIL 1: node01 is still cordoned (spec.unschedulable=true)"
  fail=1
else
  echo "PASS 1: node01 is uncordoned (spec.unschedulable=${unsched:-<null>})"
fi

# Check 2: a Deployment in default is scaled to 6 (name not fixed by the task)
deploy=$(kubectl get deploy -n default -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.replicas}{"\n"}{end}' 2>/dev/null \
  | awk '$2=="6" {print $1; exit}')
if [ -n "$deploy" ]; then
  echo "PASS 2: deployment $deploy has 6 replicas"
else
  names=$(kubectl get deploy -n default -o jsonpath='{range .items[*]}{.metadata.name}{"="}{.spec.replicas}{" "}{end}' 2>/dev/null)
  echo "FAIL 2: no Deployment with 6 replicas in default (found: ${names:-none})"
  fail=1
fi

# Check 3: all 6 pods of that Deployment are Ready
ready=$(kubectl get deployment "$deploy" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$ready" = "6" ]; then
  echo "PASS 3: 6 ${deploy:-deployment} pods Ready"
else
  echo "FAIL 3: expected 6 ready pods (readyReplicas=${ready:-0})"
  fail=1
fi

# Pods of the Deployment: walk Deployment -> ReplicaSets -> pods by
# ownerReferences, so the pod labels do not matter.
rs_names=$(kubectl get rs -n default -o jsonpath='{range .items[*]}{.metadata.ownerReferences[0].name}{" "}{.metadata.name}{"\n"}{end}' 2>/dev/null \
  | awk -v d="$deploy" '$1==d {print $2}')
pod_nodes=$(kubectl get pods -n default -o jsonpath='{range .items[*]}{.metadata.ownerReferences[0].name}{" "}{.spec.nodeName}{"\n"}{end}' 2>/dev/null \
  | awk -v list="$rs_names" 'BEGIN{n=split(list,a,"\n"); for(i=1;i<=n;i++) if(a[i]!="") rs[a[i]]=1} ($1 in rs) {print $2}')

# Check 4: at least one pod of the Deployment scheduled on node01
on_node01=$(echo "$pod_nodes" | grep -c '^node01$')
if [ "$on_node01" -ge 1 ]; then
  echo "PASS 4: ${on_node01} ${deploy:-deployment} pod(s) on node01"
else
  echo "FAIL 4: no ${deploy:-deployment} pods on node01"
  fail=1
fi

# Check 5: pods spread - at least one pod of the Deployment on controlplane
on_cp=$(echo "$pod_nodes" | grep -c '^controlplane$')
if [ "$on_cp" -ge 1 ]; then
  echo "PASS 5: ${on_cp} ${deploy:-deployment} pod(s) on controlplane"
else
  echo "FAIL 5: no ${deploy:-deployment} pods on controlplane"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - node01 uncordoned, ${deploy} at 6 replicas spread across both nodes"
exit 0
