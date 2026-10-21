#!/bin/bash
# C01 step 1: snapshot /opt/snapshot-pre-boot.db saved with a valid
# status (hash + size) and deployment after-snapshot exists in default.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# Check 1: snapshot file /opt/snapshot-pre-boot.db exists and is non-empty
size=$(stat -c %s /opt/snapshot-pre-boot.db 2>/dev/null)
if [ -n "$size" ] && [ "$size" -gt 0 ]; then
  echo "PASS 1: /opt/snapshot-pre-boot.db exists (size=${size} bytes)"
else
  echo "FAIL 1: /opt/snapshot-pre-boot.db missing or empty (size=${size:-0} bytes)"
  fail=1
fi

# Check 2: etcdctl snapshot status reports a hash and a size
out=$(ETCDCTL_API=3 etcdctl snapshot status /opt/snapshot-pre-boot.db -w table 2>&1)
if echo "$out" | grep -qE '^\| [0-9a-f]{8} ' && echo "$out" | grep -qE '[0-9.]+ (KB|MB|GB)'; then
  echo "PASS 2: snapshot status shows a hash and a size"
else
  echo "FAIL 2: snapshot status missing hash or size (got: $(echo "$out" | tr '\n' ' ' | cut -c1-160))"
  fail=1
fi

# Check 3: deployment after-snapshot exists in default
name=$(kubectl get deploy after-snapshot -o jsonpath='{.metadata.name}' 2>/dev/null)
if [ "$name" = "after-snapshot" ]; then
  echo "PASS 3: deployment after-snapshot exists"
else
  echo "FAIL 3: deployment after-snapshot not found (name=${name:-none})"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - snapshot saved and after-snapshot deployment exists"
exit 0
