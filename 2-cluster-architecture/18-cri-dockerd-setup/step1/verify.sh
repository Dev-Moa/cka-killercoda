#!/bin/bash
# 18-cri-dockerd-setup: kernel modules, sysctl parameters, Docker,
# cri-dockerd binary, systemd units and the CRI socket on controlplane.
# Evidence-only checks, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# Check 1: overlay kernel module is loaded
if lsmod | awk '{print $1}' | grep -qx overlay; then
  echo "PASS 1: overlay kernel module is loaded"
else
  echo "FAIL 1: overlay kernel module is not loaded"
  fail=1
fi

# Check 2: br_netfilter kernel module is loaded
if lsmod | awk '{print $1}' | grep -qx br_netfilter; then
  echo "PASS 2: br_netfilter kernel module is loaded"
else
  echo "FAIL 2: br_netfilter kernel module is not loaded"
  fail=1
fi

# Check 3: sysctl net.bridge.bridge-nf-call-iptables is 1
v=$(sysctl -n net.bridge.bridge-nf-call-iptables 2>/dev/null)
if [ "$v" = "1" ]; then
  echo "PASS 3: sysctl net.bridge.bridge-nf-call-iptables = 1"
else
  echo "FAIL 3: sysctl net.bridge.bridge-nf-call-iptables expected 1, got ${v:-unset}"
  fail=1
fi

# Check 4: sysctl net.ipv4.ip_forward is 1
v=$(sysctl -n net.ipv4.ip_forward 2>/dev/null)
if [ "$v" = "1" ]; then
  echo "PASS 4: sysctl net.ipv4.ip_forward = 1"
else
  echo "FAIL 4: sysctl net.ipv4.ip_forward expected 1, got ${v:-unset}"
  fail=1
fi

# Check 5: docker.service is active (cri-dockerd needs a running Docker)
v=$(systemctl is-active docker 2>/dev/null)
if [ "$v" = "active" ]; then
  echo "PASS 5: docker.service is active"
else
  echo "FAIL 5: docker.service expected active, got ${v:-not found}"
  fail=1
fi

# Check 6: cri-dockerd binary is installed and executable
if [ -x /usr/local/bin/cri-dockerd ]; then
  echo "PASS 6: /usr/local/bin/cri-dockerd is installed and executable"
else
  echo "FAIL 6: /usr/local/bin/cri-dockerd missing or not executable"
  fail=1
fi

# Check 7: systemd unit file cri-docker.service exists
if [ -f /etc/systemd/system/cri-docker.service ]; then
  echo "PASS 7: unit file /etc/systemd/system/cri-docker.service exists"
else
  echo "FAIL 7: unit file /etc/systemd/system/cri-docker.service missing"
  fail=1
fi

# Check 8: systemd unit file cri-docker.socket exists
if [ -f /etc/systemd/system/cri-docker.socket ]; then
  echo "PASS 8: unit file /etc/systemd/system/cri-docker.socket exists"
else
  echo "FAIL 8: unit file /etc/systemd/system/cri-docker.socket missing"
  fail=1
fi

# Check 9: cri-docker.service is active
v=$(systemctl is-active cri-docker.service 2>/dev/null)
if [ "$v" = "active" ]; then
  echo "PASS 9: cri-docker.service is active"
else
  echo "FAIL 9: cri-docker.service expected active, got ${v:-not found}"
  fail=1
fi

# Check 10: cri-docker.socket is active
v=$(systemctl is-active cri-docker.socket 2>/dev/null)
if [ "$v" = "active" ]; then
  echo "PASS 10: cri-docker.socket is active"
else
  echo "FAIL 10: cri-docker.socket expected active, got ${v:-not found}"
  fail=1
fi

# Check 11: cri-docker.service is enabled
v=$(systemctl is-enabled cri-docker.service 2>/dev/null)
if [ "$v" = "enabled" ]; then
  echo "PASS 11: cri-docker.service is enabled"
else
  echo "FAIL 11: cri-docker.service expected enabled, got ${v:-not found}"
  fail=1
fi

# Check 12: cri-docker.socket is enabled
v=$(systemctl is-enabled cri-docker.socket 2>/dev/null)
if [ "$v" = "enabled" ]; then
  echo "PASS 12: cri-docker.socket is enabled"
else
  echo "FAIL 12: cri-docker.socket expected enabled, got ${v:-not found}"
  fail=1
fi

# Check 13: socket exists at /run/cri-dockerd.sock and the socket unit
# really listens there (a hand-made file does not count)
listen=$(systemctl show -p Listen --value cri-docker.socket 2>/dev/null)
if [ -S /run/cri-dockerd.sock ] && echo "$listen" | grep -q "/run/cri-dockerd.sock"; then
  echo "PASS 13: socket /run/cri-dockerd.sock exists and cri-docker.socket listens there"
else
  echo "FAIL 13: expected a listening socket at /run/cri-dockerd.sock (unit Listen=${listen:-none})"
  fail=1
fi

# Check 14: the CRI endpoint answers (crictl through cri-dockerd)
if crictl --runtime-endpoint=unix:///run/cri-dockerd.sock version >/dev/null 2>&1; then
  echo "PASS 14: crictl reaches the cri-dockerd CRI endpoint"
else
  echo "FAIL 14: crictl cannot reach unix:///run/cri-dockerd.sock"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - cri-dockerd installed, running and serving CRI"
exit 0
