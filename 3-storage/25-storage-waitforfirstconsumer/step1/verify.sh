#!/bin/bash
# 25: StorageClass local-storage (WaitForFirstConsumer), local PV
# local-pv-1, PVC local-pvc Bound to it, a busybox pod in exercise-25
# mounting the PVC at /data on the PV's node, with a file written.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0
NS=exercise-25

# Check 1: namespace exercise-25 exists
if kubectl get ns "$NS" >/dev/null 2>&1; then
  echo "PASS 1: namespace $NS exists"
else
  echo "FAIL 1: namespace $NS not found"
  fail=1
fi

# Check 2: StorageClass local-storage - no-provisioner, WaitForFirstConsumer
prov=$(kubectl get storageclass local-storage -o jsonpath='{.provisioner}' 2>/dev/null)
mode=$(kubectl get storageclass local-storage -o jsonpath='{.volumeBindingMode}' 2>/dev/null)
if [ "$prov" = "kubernetes.io/no-provisioner" ] && [ "$mode" = "WaitForFirstConsumer" ]; then
  echo "PASS 2: StorageClass local-storage uses kubernetes.io/no-provisioner with WaitForFirstConsumer"
else
  echo "FAIL 2: StorageClass local-storage expected provisioner=kubernetes.io/no-provisioner volumeBindingMode=WaitForFirstConsumer (got provisioner=${prov:-not found} volumeBindingMode=${mode:-none})"
  fail=1
fi

# Check 3: PV local-pv-1 - 1Gi, ReadWriteOnce, class local-storage, a
# local path (any path is allowed by the task)
pv=$(kubectl get pv local-pv-1 -o jsonpath='{.spec.capacity.storage}|{.spec.accessModes}|{.spec.storageClassName}|{.spec.local.path}' 2>/dev/null)
IFS='|' read -r cap modes sc lpath <<< "$pv"
if [ -z "$pv" ]; then
  echo "FAIL 3: PV local-pv-1 not found"
  fail=1
else
  ok=1
  [ "$cap" = "1Gi" ] || ok=0
  case "$modes" in *'"ReadWriteOnce"'*) : ;; *) ok=0 ;; esac
  [ "$sc" = "local-storage" ] || ok=0
  [ -n "$lpath" ] || ok=0
  if [ "$ok" = "1" ]; then
    echo "PASS 3: PV local-pv-1 is 1Gi ReadWriteOnce, class local-storage, local path $lpath"
  else
    echo "FAIL 3: PV local-pv-1 expected capacity=1Gi accessModes=[ReadWriteOnce] storageClassName=local-storage with spec.local.path set (got capacity=${cap:-none} accessModes=${modes:-none} storageClassName=${sc:-none} local.path=${lpath:-none})"
    fail=1
  fi
fi

# Check 4: PVC local-pvc in exercise-25 - 1Gi, class local-storage
req=$(kubectl get pvc local-pvc -n "$NS" -o jsonpath='{.spec.resources.requests.storage}' 2>/dev/null)
sc=$(kubectl get pvc local-pvc -n "$NS" -o jsonpath='{.spec.storageClassName}' 2>/dev/null)
if [ "$req" = "1Gi" ] && [ "$sc" = "local-storage" ]; then
  echo "PASS 4: PVC local-pvc in $NS requests 1Gi with class local-storage"
else
  echo "FAIL 4: PVC local-pvc in $NS expected requests.storage=1Gi storageClassName=local-storage (got storage=${req:-not found} storageClassName=${sc:-none})"
  fail=1
fi

# Check 5: PVC local-pvc is Bound to local-pv-1 (binding happened once a pod used it)
phase=$(kubectl get pvc local-pvc -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null)
vol=$(kubectl get pvc local-pvc -n "$NS" -o jsonpath='{.spec.volumeName}' 2>/dev/null)
if [ "$phase" = "Bound" ] && [ "$vol" = "local-pv-1" ]; then
  echo "PASS 5: PVC local-pvc is Bound to PV local-pv-1"
else
  echo "FAIL 5: PVC local-pvc expected phase=Bound volumeName=local-pv-1 (got phase=${phase:-none} volumeName=${vol:-none}) - with WaitForFirstConsumer it binds only once a pod mounts it"
  fail=1
fi

# Check 6: a Running pod in exercise-25 (name is the candidate's choice)
# mounting PVC local-pvc at /data
pod=""
for p in $(kubectl get pods -n "$NS" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
  ph=$(kubectl get pod "$p" -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null)
  volname=$(kubectl get pod "$p" -n "$NS" -o jsonpath='{.spec.volumes[?(@.persistentVolumeClaim.claimName=="local-pvc")].name}' 2>/dev/null)
  [ "$ph" = "Running" ] && [ -n "$volname" ] || continue
  mount=$(kubectl get pod "$p" -n "$NS" -o jsonpath="{.spec.containers[*].volumeMounts[?(@.name==\"$volname\")].mountPath}" 2>/dev/null)
  echo " $mount " | grep -q ' /data ' || continue
  pod=$p; break
done
if [ -n "$pod" ]; then
  echo "PASS 6: pod $pod in $NS is Running with PVC local-pvc mounted at /data"
else
  pods=$(kubectl get pods -n "$NS" -o jsonpath='{range .items[*]}{.metadata.name}{"="}{.status.phase}{" "}{end}' 2>/dev/null)
  echo "FAIL 6: no Running pod in $NS mounts PVC local-pvc at /data (pods: ${pods:-none})"
  fail=1
fi

# Check 7: that pod uses image busybox:1.36
if [ -n "$pod" ]; then
  images=$(kubectl get pod "$pod" -n "$NS" -o jsonpath='{.spec.containers[*].image}' 2>/dev/null)
  if echo " $images " | grep -q ' busybox:1.36 '; then
    echo "PASS 7: pod $pod uses image busybox:1.36"
  else
    echo "FAIL 7: pod $pod expected image busybox:1.36 (got ${images:-none})"
    fail=1
  fi
else
  echo "FAIL 7: no consumer pod found, image not checked"
  fail=1
fi

# Check 8: the pod runs on the node the PV is pinned to (task 7)
if [ -n "$pod" ]; then
  node=$(kubectl get pod "$pod" -n "$NS" -o jsonpath='{.spec.nodeName}' 2>/dev/null)
  pvnodes=$(kubectl get pv local-pv-1 -o jsonpath='{.spec.nodeAffinity.required.nodeSelectorTerms[*].matchExpressions[?(@.key=="kubernetes.io/hostname")].values[*]}' 2>/dev/null)
  if [ -n "$node" ] && echo " $pvnodes " | grep -q " $node "; then
    echo "PASS 8: pod $pod runs on $node, the node PV local-pv-1 is pinned to"
  else
    echo "FAIL 8: pod $pod runs on ${node:-no node}, PV local-pv-1 nodeAffinity names ${pvnodes:-no kubernetes.io/hostname values}"
    fail=1
  fi
else
  echo "FAIL 8: no consumer pod found, node placement not checked"
  fail=1
fi

# Check 9: data was written into the volume (task 8). Any file name
# counts - the content is never checked.
if [ -n "$pod" ]; then
  files=$(kubectl exec "$pod" -n "$NS" -- ls -A /data 2>/dev/null | grep -c .)
  if [ "${files:-0}" -ge 1 ]; then
    echo "PASS 9: /data in pod $pod holds $files file(s)"
  else
    echo "FAIL 9: /data in pod $pod is empty - write a test file into the volume (task 8)"
    fail=1
  fi
else
  echo "FAIL 9: no consumer pod found, volume content not checked"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - local-storage class, local-pv-1 bound to local-pvc, consumer pod Running on the PV node with data written"
exit 0
