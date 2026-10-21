## What tripped me up

> **Pod Debug Trap:** I ran `k debug broken-app -it --image=busybox:1.36` without `--target=broken-app`. The debug container started, but `ps aux` only showed my busybox shell — no nginx processes. Without `--target`, the debug container gets its own process namespace. You NEED `--target=<container>` to share process namespace with the container you're debugging. This is the most common k8s 1.35 gotcha: `--target` is not optional; it's the difference between isolated debugging and actual container inspection.
>
> **Node Debug Trap:** Node debugging without `chroot /host` leaves you in the debug pod's filesystem, not the real node. `systemctl status kubelet` fails because systemd isn't mounted. After `chroot /host`, you get full node access. Common mistake: spending 5 minutes trying to find config files that don't exist in the container root.
>
> **May 2026 Gotcha (Image Availability):** If you specify `--image=busybox:1.36` but the node doesn't have it cached, `kubectl debug` will pull it. On exam nodes with slow network or no direct internet access, this can timeout silently. Fallback: use `--image=ubuntu:22.04` or whatever is already cached. Check: `crictl images` on the node first.
>
> **Debug Container Port Forwarding Gotcha:** From inside a debug pod in the pod namespace, you can `curl localhost:80` to test the target container's port. But from node debug, `localhost` is the node, not a specific service. You need to either `curl <service-ip>` (find with `k get svc`) or `curl <pod-ip>:port` (find in target pod). Make sure you understand the network stack level you're debugging.
>
> **Multiple Containers Trap:** If the pod has multiple containers, `--target` specifies which ONE. If you `--target=container-a` but the pod's issue is in `container-b`, you won't see the broken process. Always verify which container the issue is in before attaching the debug pod.
>
> **Resource Limits on Debug Pod:** kubectl debug respects node resource limits. If a node is under resource pressure, you might not be able to spawn a debug pod. This is exam-realistic: you want to debug a problem but the cluster is too broken to create debug resources. Verify: `k describe node` for pressure conditions before failing debug as "not working."

<details>
<summary>Solution</summary>

### Part A

```bash
k create ns exercise-17

k run broken-app -n exercise-17 --image=nginx:1.27

# Wait for running
k get pod broken-app -n exercise-17 -w

# Debug with shared process namespace
k debug broken-app -n exercise-17 -it --image=busybox:1.36 --target=broken-app

# Inside the debug container:
ps aux                      # should show nginx master + worker processes
ls /proc/1/root/etc/nginx/  # access the target container filesystem
wget -qO- localhost:80      # test connectivity from inside
exit
```

### Part B

```bash
# Get a node name
k get nodes
# e.g., node-1

k debug node/node-1 -it --image=busybox:1.36

# Inside:
chroot /host

# Now you have real node access
systemctl status kubelet
journalctl -u kubelet --no-pager | tail -20
crictl ps
cat /etc/kubernetes/manifests/kube-apiserver.yaml | head -20

exit  # exit chroot
exit  # exit debug pod
```

</details>
