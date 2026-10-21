#!/bin/bash
# Part A setup, from the exercise (run hidden on controlplane):
#   sudo sed -i 's/kube-scheduler$/kube-schedulerr/' /etc/kubernetes/manifests/kube-scheduler.yaml
#   kubectl create deployment test --image=nginx --replicas=2
# The sed changes every line ending in "kube-scheduler" - the command,
# the container name and metadata.name - so the mirror pod is renamed
# and crash-loops on exec "kube-schedulerr": not found.
sudo sed -i 's/kube-scheduler$/kube-schedulerr/' /etc/kubernetes/manifests/kube-scheduler.yaml   # typo in the command

# Wait until the kubelet has torn down the old (working) scheduler pod,
# so the test deployment cannot be scheduled by it in the last seconds.
for i in $(seq 1 30); do
  kubectl --request-timeout=10s get pod kube-scheduler-controlplane -n kube-system >/dev/null 2>&1 || break
  sleep 2
done
sleep 5

kubectl create deployment test --image=nginx --replicas=2
exit 0
