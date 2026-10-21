#!/bin/bash
# 12 step 1: PV my-pv, PVC my-pvc Bound to it, pod storage-consumer
# Running in exercise-12 with the PVC mounted at /data and a file in it.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0
NS=exercise-12

# Check 1: namespace exercise-12 exists
if kubectl get ns "$NS" >/dev/null 2>&1; then
  echo "PASS 1: namespace $NS exists"
else
  echo "FAIL 1: namespace $NS not found"
  fail=1
fi

# Check 2: PV my-pv spec - 1Gi, ReadWriteOnce, storageClassName manual,
# hostPath /data/exercise-12, reclaim policy Retain
pv=$(kubectl get pv my-pv -o jsonpath='{.spec.capacity.storage}|{.spec.accessModes}|{.spec.storageClassName}|{.spec.hostPath.path}|{.spec.persistentVolumeReclaimPolicy}' 2>/dev/null)
IFS='|' read -r cap modes sc hp policy <<< "$pv"
if [ -z "$pv" ]; then
  echo "FAIL 2: PV my-pv not found"
  fail=1
else
  ok=1
  [ "$cap" = "1Gi" ] || ok=0
  case "$modes" in *'"ReadWriteOnce"'*) : ;; *) ok=0 ;; esac
  [ "$sc" = "manual" ] || ok=0
  [ "$hp" = "/data/exercise-12" ] || ok=0
  [ "$policy" = "Retain" ] || ok=0
  if [ "$ok" = "1" ]; then
    echo "PASS 2: PV my-pv is 1Gi ReadWriteOnce, class manual, hostPath /data/exercise-12, reclaim Retain"
  else
    echo "FAIL 2: PV my-pv expected capacity=1Gi accessModes=[ReadWriteOnce] storageClassName=manual hostPath=/data/exercise-12 reclaimPolicy=Retain (got capacity=${cap:-none} accessModes=${modes:-none} storageClassName=${sc:-none} hostPath=${hp:-none} reclaimPolicy=${policy:-none})"
    fail=1
  fi
fi

# Check 3: PVC my-pvc in exercise-12 - 500Mi, ReadWriteOnce, class manual
pvc=$(kubectl get pvc my-pvc -n "$NS" -o jsonpath='{.spec.resources.requests.storage}|{.spec.accessModes}|{.spec.storageClassName}' 2>/dev/null)
IFS='|' read -r req modes sc <<< "$pvc"
if [ -z "$pvc" ]; then
  echo "FAIL 3: PVC my-pvc not found in $NS"
  fail=1
else
  ok=1
  [ "$req" = "500Mi" ] || ok=0
  case "$modes" in *'"ReadWriteOnce"'*) : ;; *) ok=0 ;; esac
  [ "$sc" = "manual" ] || ok=0
  if [ "$ok" = "1" ]; then
    echo "PASS 3: PVC my-pvc in $NS requests 500Mi ReadWriteOnce with class manual"
  else
    echo "FAIL 3: PVC my-pvc expected requests.storage=500Mi accessModes=[ReadWriteOnce] storageClassName=manual (got storage=${req:-none} accessModes=${modes:-none} storageClassName=${sc:-none})"
    fail=1
  fi
fi

# Check 4: PVC my-pvc is Bound to PV my-pv
phase=$(kubectl get pvc my-pvc -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null)
vol=$(kubectl get pvc my-pvc -n "$NS" -o jsonpath='{.spec.volumeName}' 2>/dev/null)
if [ "$phase" = "Bound" ] && [ "$vol" = "my-pv" ]; then
  echo "PASS 4: PVC my-pvc is Bound to PV my-pv"
else
  echo "FAIL 4: PVC my-pvc expected phase=Bound volumeName=my-pv (got phase=${phase:-none} volumeName=${vol:-none}) - check capacity, accessModes and storageClassName match the PV"
  fail=1
fi

# Check 5: pod storage-consumer in exercise-12 is Running
phase=$(kubectl get pod storage-consumer -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$phase" = "Running" ]; then
  echo "PASS 5: pod storage-consumer in $NS is Running"
else
  echo "FAIL 5: pod storage-consumer in $NS expected Running (got phase=${phase:-not found})"
  fail=1
fi

# Check 6: the pod mounts PVC my-pvc at /data
volname=$(kubectl get pod storage-consumer -n "$NS" -o jsonpath='{.spec.volumes[?(@.persistentVolumeClaim.claimName=="my-pvc")].name}' 2>/dev/null)
mount=""
if [ -n "$volname" ]; then
  mount=$(kubectl get pod storage-consumer -n "$NS" -o jsonpath="{.spec.containers[*].volumeMounts[?(@.name==\"$volname\")].mountPath}" 2>/dev/null)
fi
if [ -n "$volname" ] && echo " $mount " | grep -q ' /data '; then
  echo "PASS 6: pod storage-consumer mounts PVC my-pvc (volume $volname) at /data"
else
  echo "FAIL 6: pod storage-consumer must have a volume with persistentVolumeClaim.claimName=my-pvc mounted at /data (got volume=${volname:-none} mountPath=${mount:-none})"
  fail=1
fi

# Check 7: a file was written into the mounted volume (tasks 6-7). Any
# file name counts - the content is never checked.
files=$(kubectl exec storage-consumer -n "$NS" -- ls -A /data 2>/dev/null | grep -c .)
if [ "${files:-0}" -ge 1 ]; then
  echo "PASS 7: /data in pod storage-consumer holds $files file(s) - the write persisted"
else
  echo "FAIL 7: /data in pod storage-consumer is empty - write a test file into the mounted volume (task 6)"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - my-pv bound to my-pvc, storage-consumer Running with /data mounted and written"
exit 0
