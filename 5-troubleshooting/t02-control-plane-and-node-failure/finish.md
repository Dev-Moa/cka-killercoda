Setup, on the control plane node:

```bash
sudo sed -i 's/kube-scheduler$/kube-schedulerr/' /etc/kubernetes/manifests/kube-scheduler.yaml   # typo in the command
kubectl create deployment test --image=nginx --replicas=2
```

Setup:

```bash
sudo sed -i 's/--etcd-servers=https:\/\/127.0.0.1:2379/--etcd-servers=https:\/\/127.0.0.1:2380/' /etc/kubernetes/manifests/kube-apiserver.yaml
```

Setup, on the worker node:

```bash
sudo systemctl stop kubelet
```

<details>
<summary>Solution</summary>

```bash
# Part A
kubectl get pods -l app=test                      # Pending
kubectl describe pod <test-pod> | tail            # no events, nothing scheduled it
kubectl get pods -n kube-system                   # kube-scheduler-<node> CrashLoopBackOff
kubectl logs kube-scheduler-<node> -n kube-system # or describe: exec "kube-schedulerr": not found
sudo vi /etc/kubernetes/manifests/kube-scheduler.yaml    # fix the command
kubectl get pods -n kube-system -w                # scheduler Running
kubectl get pods -l app=test -o wide              # Running

# Part B
kubectl get nodes                                 # connection refused
sudo crictl ps -a | grep kube-apiserver           # container exited and restarting
sudo crictl logs <container-id>                   # dial tcp 127.0.0.1:2380: connection refused (etcd)
sudo grep etcd-servers /etc/kubernetes/manifests/kube-apiserver.yaml
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml    # 2380 -> 2379
watch kubectl get pods -n kube-system             # apiserver back

# Part C
kubectl get nodes                                 # <worker> NotReady
kubectl describe node <worker>                    # Conditions: Ready Unknown, "Kubelet stopped posting node status", LastHeartbeatTime
ssh <worker>
sudo systemctl status kubelet                     # inactive (dead)
sudo journalctl -u kubelet -xe | tail             # last lines before the stop
sudo systemctl start kubelet
sudo systemctl status kubelet                     # active (running)
exit
kubectl get nodes                                 # Ready
```

**Key insight:** nodes first, then `kube-system` pods, then logs. With
kubeadm the control plane is static pods, so the fix is always a file
in `/etc/kubernetes/manifests/` and the kubelet does the restart. When
the API server itself is down, `kubectl` is useless; go to `crictl` and
`journalctl` on the node. A node whose conditions say `Unknown` has a
dead or unreachable kubelet.

</details>
