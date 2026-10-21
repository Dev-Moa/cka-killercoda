#!/bin/bash
# C01 step 2: etcd restored - etcd pod Running on /var/lib/etcd-from-backup
# and deployment after-snapshot is gone from default.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# Check 1: etcd static pod is Running again
phase=$(kubectl get pod -n kube-system -l component=etcd -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
if [ "$phase" = "Running" ]; then
  echo "PASS 1: etcd pod is Running"
else
  echo "FAIL 1: etcd pod not Running (phase=${phase:-not found})"
  fail=1
fi

# Check 2: etcd-data volume hostPath points at the restored directory
hp=$(kubectl get pod -n kube-system -l component=etcd -o jsonpath="{.items[0].spec.volumes[?(@.name==\"etcd-data\")].hostPath.path}" 2>/dev/null)
if [ "$hp" = "/var/lib/etcd-from-backup" ]; then
  echo "PASS 2: etcd pod uses data dir /var/lib/etcd-from-backup"
else
  echo "FAIL 2: expected etcd-data hostPath /var/lib/etcd-from-backup (got ${hp:-none})"
  fail=1
fi

# Check 3: the restored data directory exists with member data
if [ -d /var/lib/etcd-from-backup/member ]; then
  echo "PASS 3: /var/lib/etcd-from-backup exists with member data"
else
  echo "FAIL 3: /var/lib/etcd-from-backup/member not found"
  fail=1
fi

# Check 4: deployment after-snapshot is gone (NotFound)
err=$(kubectl get deploy after-snapshot 2>&1)
if echo "$err" | grep -q "NotFound"; then
  echo "PASS 4: deployment after-snapshot is gone"
else
  echo "FAIL 4: deployment after-snapshot still exists (got: $(echo "$err" | head -1 | cut -c1-120))"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - etcd restored on /var/lib/etcd-from-backup and after-snapshot is gone"
exit 0
