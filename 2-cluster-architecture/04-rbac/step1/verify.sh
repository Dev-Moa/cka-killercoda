#!/bin/bash
# 04-rbac: RBAC objects for namespace exercise-04 (Role, RoleBinding,
# ClusterRole, ClusterRoleBinding). Evidence-only output, also written
# to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# Helper: does the rendered text contain the quoted token "$2"?
has() { case "$1" in *'"'$2'"'*) return 0 ;; esac; return 1; }

# Check 1: namespace exercise-04 exists
if kubectl get ns exercise-04 -o name >/dev/null 2>&1; then
  echo "PASS 1: namespace exercise-04 exists"
else
  echo "FAIL 1: namespace exercise-04 not found"
  fail=1
fi

# Check 2: ServiceAccount dev-sa exists in exercise-04
if kubectl get sa dev-sa -n exercise-04 -o name >/dev/null 2>&1; then
  echo "PASS 2: ServiceAccount dev-sa exists in exercise-04"
else
  echo "FAIL 2: ServiceAccount dev-sa not found in exercise-04"
  fail=1
fi

# Check 3: Role pod-manager exists in exercise-04
if kubectl get role pod-manager -n exercise-04 -o name >/dev/null 2>&1; then
  echo "PASS 3: Role pod-manager exists in exercise-04"
else
  echo "FAIL 3: Role pod-manager not found in exercise-04"
  fail=1
fi

# Check 4: pod-manager pods rule = core group, get/list/watch/create/delete
pods_lines=$(kubectl get role pod-manager -n exercise-04 -o jsonpath='{range .rules[*]}{.apiGroups} {.resources} {.verbs}{"\n"}{end}' 2>/dev/null | grep -F '"pods"')
pods_ok=1
case "$pods_lines" in *'[""]'*|*'["*"]'*) : ;; *) pods_ok=0 ;; esac
for v in get list watch create delete; do has "$pods_lines" "$v" || pods_ok=0; done
if [ "$pods_ok" = "1" ]; then
  echo 'PASS 4: pod-manager grants pods get,list,watch,create,delete in the core group'
else
  echo "FAIL 4: pod-manager pods rule expected apiGroups=[\"\"] verbs=get,list,watch,create,delete (got: ${pods_lines:-<none>})"
  fail=1
fi

# Check 5: pod-manager services rule = core group, get/list, no delete
svc_lines=$(kubectl get role pod-manager -n exercise-04 -o jsonpath='{range .rules[*]}{.apiGroups} {.resources} {.verbs}{"\n"}{end}' 2>/dev/null | grep -F '"services"')
svc_ok=1
case "$svc_lines" in *'[""]'*|*'["*"]'*) : ;; *) svc_ok=0 ;; esac
has "$svc_lines" get || svc_ok=0
has "$svc_lines" list || svc_ok=0
has "$svc_lines" delete && svc_ok=0
if [ "$svc_ok" = "1" ]; then
  echo 'PASS 5: pod-manager grants services get,list (no delete)'
else
  echo "FAIL 5: pod-manager services rule expected apiGroups=[\"\"] verbs=get,list only (got: ${svc_lines:-<none>})"
  fail=1
fi

# Check 6: no rule grants deployments (Verify: delete deployments = "no")
role_res=$(kubectl get role pod-manager -n exercise-04 -o jsonpath='{.rules[*].resources}' 2>/dev/null)
if ! has "$role_res" deployments; then
  echo 'PASS 6: pod-manager grants no deployments (delete deployments stays "no")'
else
  echo "FAIL 6: pod-manager must not include deployments (got: ${role_res:-<none>})"
  fail=1
fi

# Check 7: RoleBinding dev-pod-access binds Role pod-manager to SA dev-sa
rb=$(kubectl get rolebinding dev-pod-access -n exercise-04 -o jsonpath='{.roleRef.kind} {.roleRef.name} {.subjects[*].kind} {.subjects[*].name}' 2>/dev/null)
if [ "$rb" = "Role pod-manager ServiceAccount dev-sa" ]; then
  echo 'PASS 7: dev-pod-access binds Role pod-manager to ServiceAccount dev-sa'
else
  echo "FAIL 7: expected roleRef=Role/pod-manager subject=ServiceAccount/dev-sa (got: ${rb:-<none>})"
  fail=1
fi

# Check 8: ClusterRole node-viewer grants nodes get,list, no pods rule
node_lines=$(kubectl get clusterrole node-viewer -o jsonpath='{range .rules[*]}{.apiGroups} {.resources} {.verbs}{"\n"}{end}' 2>/dev/null | grep -F '"nodes"')
node_ok=1
case "$node_lines" in *'[""]'*|*'["*"]'*) : ;; *) node_ok=0 ;; esac
has "$node_lines" get || node_ok=0
has "$node_lines" list || node_ok=0
cr_res=$(kubectl get clusterrole node-viewer -o jsonpath='{.rules[*].resources}' 2>/dev/null)
has "$cr_res" pods && node_ok=0
if [ "$node_ok" = "1" ]; then
  echo 'PASS 8: node-viewer grants nodes get,list in the core group (no pods)'
else
  echo "FAIL 8: node-viewer expected nodes get,list only, no pods (got: ${node_lines:-<none>})"
  fail=1
fi

# Check 9: ClusterRoleBinding dev-node-access binds node-viewer to dev-sa
crb=$(kubectl get clusterrolebinding dev-node-access -o jsonpath='{.roleRef.kind} {.roleRef.name} {.subjects[*].kind} {.subjects[*].name} {.subjects[*].namespace}' 2>/dev/null)
if [ "$crb" = "ClusterRole node-viewer ServiceAccount dev-sa exercise-04" ]; then
  echo 'PASS 9: dev-node-access binds ClusterRole node-viewer to ServiceAccount dev-sa'
else
  echo "FAIL 9: expected roleRef=ClusterRole/node-viewer subject=ServiceAccount dev-sa in exercise-04 (got: ${crb:-<none>})"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - RBAC objects for dev-sa in exercise-04 all correct"
exit 0
