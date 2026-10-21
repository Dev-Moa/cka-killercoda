#!/bin/bash
# 26-cri-dockerd-setup: cri-dockerd installed and running on node01,
# kubelet pointed at its socket, node01 Ready.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# The exercise works on the worker node, so all node checks go over ssh.
sshq() {
  ssh -o BatchMode=yes -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 node01 "$@" 2>/dev/null
}

# Check 1: cri-dockerd socket exists on node01
if sshq 'test -S /run/cri-dockerd.sock'; then
  echo "PASS 1: /run/cri-dockerd.sock exists on node01"
else
  echo "FAIL 1: /run/cri-dockerd.sock not found on node01"
  fail=1
fi

# Check 2: cri-dockerd service is active on node01
state=$(sshq 'systemctl is-active cri-dockerd')
if [ "$state" = "active" ]; then
  echo "PASS 2: cri-dockerd service is active on node01"
else
  echo "FAIL 2: cri-dockerd service not active on node01 (state=${state:-unknown}, expected active)"
  fail=1
fi

# Check 3: cri-dockerd service is enabled on node01
enabled=$(sshq 'systemctl is-enabled cri-dockerd 2>/dev/null')
if [ "$enabled" = "enabled" ]; then
  echo "PASS 3: cri-dockerd service is enabled on node01"
else
  echo "FAIL 3: cri-dockerd service not enabled on node01 (got=${enabled:-unknown}, expected enabled)"
  fail=1
fi

# Check 4: kernel modules overlay and br_netfilter loaded on node01
mods=$(sshq 'lsmod | grep -oE "^(overlay|br_netfilter)"')
if echo "$mods" | grep -q "^overlay$" && echo "$mods" | grep -q "^br_netfilter$"; then
  echo "PASS 4: overlay and br_netfilter modules loaded on node01"
else
  echo "FAIL 4: expected overlay and br_netfilter loaded on node01 (got=${mods:-none})"
  fail=1
fi

# Check 5: IP forwarding enabled on node01
fwd=$(sshq 'cat /proc/sys/net/ipv4/ip_forward')
if [ "$fwd" = "1" ]; then
  echo "PASS 5: IP forwarding enabled on node01 (net.ipv4.ip_forward=1)"
else
  echo "FAIL 5: IP forwarding disabled on node01 (ip_forward=${fwd:-unknown}, expected 1)"
  fail=1
fi

# Check 6: kubelet configured to use the cri-dockerd socket on node01
cfg=$(sshq 'grep -h "cri-dockerd" /etc/kubernetes/kubelet.conf /etc/sysconfig/kubelet /etc/default/kubelet /var/lib/kubelet/config.yaml 2>/dev/null')
if echo "$cfg" | grep -q "cri-dockerd"; then
  echo "PASS 6: kubelet config on node01 points at the cri-dockerd socket"
else
  echo "FAIL 6: kubelet config on node01 has no cri-dockerd endpoint (got=${cfg:-none})"
  fail=1
fi

# Check 7: node01 is Ready
ready=$(kubectl get node node01 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
if [ "$ready" = "True" ]; then
  echo "PASS 7: node01 is Ready"
else
  echo "FAIL 7: node01 not Ready (ready=${ready:-not found}, expected True)"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - cri-dockerd running on node01, kubelet uses it, node Ready"
exit 0
