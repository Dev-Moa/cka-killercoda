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

# The Mirantis package installs the units as cri-docker.service and
# cri-docker.socket (no trailing d). Accept a hand-made cri-dockerd unit too.
unit=$(sshq 'for u in cri-docker.service cri-dockerd.service; do systemctl cat "$u" >/dev/null 2>&1 && { echo "$u"; break; }; done')
unit=${unit:-cri-docker.service}

# Check 2: cri-dockerd service is active on node01
state=$(sshq "systemctl is-active $unit")
if [ "$state" = "active" ]; then
  echo "PASS 2: $unit is active on node01"
else
  echo "FAIL 2: $unit not active on node01 (state=${state:-unknown}, expected active)"
  fail=1
fi

# Check 3: cri-dockerd service is enabled on node01
enabled=$(sshq "systemctl is-enabled $unit 2>/dev/null")
if [ "$enabled" = "enabled" ]; then
  echo "PASS 3: $unit is enabled on node01"
else
  echo "FAIL 3: $unit not enabled on node01 (got=${enabled:-unknown}, expected enabled)"
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

# Check 6: kubelet configured to use the cri-dockerd socket on node01.
# On a kubeadm node the endpoint lives in /var/lib/kubelet/kubeadm-flags.env
# (--container-runtime-endpoint=unix:///run/cri-dockerd.sock); the other
# files are accepted for non-kubeadm layouts.
cfg=$(sshq 'grep -h "cri-dockerd.sock" /var/lib/kubelet/kubeadm-flags.env /var/lib/kubelet/config.yaml /etc/default/kubelet /etc/sysconfig/kubelet /etc/systemd/system/kubelet.service.d/*.conf 2>/dev/null')
if echo "$cfg" | grep -q "cri-dockerd.sock"; then
  echo "PASS 6: kubelet config on node01 points at unix:///run/cri-dockerd.sock"
else
  echo "FAIL 6: no kubelet config on node01 names /run/cri-dockerd.sock (checked kubeadm-flags.env, config.yaml, /etc/default/kubelet, kubelet.service.d) (got=${cfg:-none})"
  fail=1
fi

# Check 7: kubelet on node01 really runs through cri-dockerd - the node
# reports a docker:// runtime instead of containerd://
runtime=$(kubectl get node node01 -o jsonpath='{.status.nodeInfo.containerRuntimeVersion}' 2>/dev/null)
case "$runtime" in
  docker://*)
    echo "PASS 7: node01 reports container runtime $runtime (kubelet uses cri-dockerd)"
    ;;
  *)
    echo "FAIL 7: node01 reports container runtime ${runtime:-unknown}, expected docker://... - restart kubelet after pointing it at cri-dockerd"
    fail=1
    ;;
esac

# Check 8: node01 is Ready
ready=$(kubectl get node node01 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
if [ "$ready" = "True" ]; then
  echo "PASS 8: node01 is Ready"
else
  echo "FAIL 8: node01 not Ready (ready=${ready:-not found}, expected True)"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - cri-dockerd running on node01, kubelet uses it, node Ready"
exit 0
