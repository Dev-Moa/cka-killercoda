#!/bin/bash
# CHECK: worker node taint, mosquito on controlplane, bee on worker with
# toleration, and the control plane taint restored. All four must pass.

# Check 1: worker node has taint spray=mortein:NoSchedule
WORKER=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -m1 node01)
if [ -z "$WORKER" ]; then echo "no worker node found"; exit 1; fi
if kubectl describe node "$WORKER" | grep Taint | grep -q 'spray=mortein:NoSchedule'; then
  echo "worker node $WORKER has taint spray=mortein:NoSchedule"
else
  echo "taint spray=mortein:NoSchedule not found on worker node $WORKER"
  exit 1
fi

# Check 2: pod mosquito is Running on the control plane node
CP=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -m1 controlplane)
if [ -z "$CP" ]; then echo "no control plane node found"; exit 1; fi
NODE=$(kubectl get pod mosquito -o jsonpath='{.spec.nodeName}' 2>/dev/null)
PHASE=$(kubectl get pod mosquito -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$NODE" = "$CP" ] && [ "$PHASE" = "Running" ]; then
  echo "pod mosquito is Running on control plane node $CP"
else
  echo "pod mosquito not Running on control plane node $CP (node='$NODE' phase='$PHASE')"
  exit 1
fi

# Check 3: pod bee is Running on the worker node with toleration spray=mortein:NoSchedule
NODE=$(kubectl get pod bee -o jsonpath='{.spec.nodeName}' 2>/dev/null)
PHASE=$(kubectl get pod bee -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$NODE" != "$WORKER" ] || [ "$PHASE" != "Running" ]; then
  echo "pod bee not Running on worker node $WORKER (node='$NODE' phase='$PHASE')"
  exit 1
fi
TOL=$(kubectl get pod bee -o jsonpath='{range .spec.tolerations[*]}{.key}{"="}{.value}{":"}{.effect}{"\n"}{end}' 2>/dev/null)
if echo "$TOL" | grep -q '^spray=mortein:NoSchedule$'; then
  echo "pod bee is Running on $WORKER with toleration spray=mortein:NoSchedule"
else
  echo "pod bee lacks toleration spray=mortein:NoSchedule"
  exit 1
fi

# Check 4: control plane node has taint node-role.kubernetes.io/control-plane:NoSchedule
if kubectl describe node "$CP" | grep Taint | grep -q 'node-role.kubernetes.io/control-plane:NoSchedule'; then
  echo "control plane node $CP has taint node-role.kubernetes.io/control-plane:NoSchedule"
else
  echo "taint node-role.kubernetes.io/control-plane:NoSchedule not found on $CP"
  exit 1
fi

echo "All checks passed: both taints present, mosquito on controlplane, bee on node01"
