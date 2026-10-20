#!/bin/bash
# Verify the node selector and affinity question (CK-X q11, checks s1-s4).

# The CK-X node names (server/agent) do not exist on this backend:
# find the two nodes by their kubeadm role column instead.
CP=$(kubectl get nodes --no-headers | awk '$3 ~ /control-plane/ {print $1; exit}')
WORKER=$(kubectl get nodes --no-headers | awk '$3 == "<none>" {print $1; exit}')
if [ -z "$WORKER" ]; then echo "no worker node found"; exit 1; fi
if [ -z "$CP" ]; then echo "no control plane node found"; exit 1; fi

# 1. Worker node labels: size=Large and color=blue.
SIZE=$(kubectl get node "$WORKER" -o jsonpath='{.metadata.labels.size}' 2>/dev/null)
COLOR=$(kubectl get node "$WORKER" -o jsonpath='{.metadata.labels.color}' 2>/dev/null)
if [ "$SIZE" = "Large" ] && [ "$COLOR" = "blue" ]; then
  echo "worker node $WORKER has labels size=Large and color=blue"
else
  echo "worker node $WORKER missing labels (size='$SIZE' color='$COLOR', need size=Large color=blue)"
  exit 1
fi

# 2. Pod data-processor is Running on the worker node.
NODE=$(kubectl get pod data-processor -o jsonpath='{.spec.nodeName}' 2>/dev/null)
PHASE=$(kubectl get pod data-processor -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$NODE" = "$WORKER" ] && [ "$PHASE" = "Running" ]; then
  echo "pod data-processor is Running on worker node $WORKER"
else
  echo "pod data-processor not Running on worker node $WORKER (node='$NODE' phase='$PHASE')"
  exit 1
fi

# 3. Exactly 3 pods with label app=blue, all Running on the worker node.
ROWS=$(kubectl get pods -l app=blue -o jsonpath='{range .items[*]}{.status.phase}{" "}{.spec.nodeName}{"\n"}{end}' 2>/dev/null)
COUNT=$(echo "$ROWS" | grep -c .)
OK=$(echo "$ROWS" | grep -c "^Running $WORKER$")
if [ "$COUNT" -eq 3 ] && [ "$OK" -eq 3 ]; then
  echo "exactly 3 pods with label app=blue, all Running on worker node $WORKER"
else
  echo "expected 3 Running app=blue pods on $WORKER (found $COUNT pods, $OK there)"
  exit 1
fi

# 4. Exactly 2 pods with label app=red, all Running on the control plane node.
ROWS=$(kubectl get pods -l app=red -o jsonpath='{range .items[*]}{.status.phase}{" "}{.spec.nodeName}{"\n"}{end}' 2>/dev/null)
COUNT=$(echo "$ROWS" | grep -c .)
OK=$(echo "$ROWS" | grep -c "^Running $CP$")
if [ "$COUNT" -eq 2 ] && [ "$OK" -eq 2 ]; then
  echo "exactly 2 pods with label app=red, all Running on control plane node $CP"
else
  echo "expected 2 Running app=red pods on $CP (found $COUNT pods, $OK there)"
  exit 1
fi

# All checks passed.
echo "All checks passed: worker labels, data-processor on the worker, blue pods on the worker, red pods on the control plane"
