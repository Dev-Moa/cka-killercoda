#!/bin/bash
# Part B setup, from the exercise (run hidden on controlplane, applied
# last, no waiting): the API server now points at etcd's PEER port 2380
# instead of the client port 2379, so it crash-loops and kubectl fails.
sudo sed -i 's/--etcd-servers=https:\/\/127.0.0.1:2379/--etcd-servers=https:\/\/127.0.0.1:2380/' /etc/kubernetes/manifests/kube-apiserver.yaml
exit 0
