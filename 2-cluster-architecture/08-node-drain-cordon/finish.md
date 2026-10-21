## What tripped me up

> I ran `k drain worker-1` without `--ignore-daemonsets` and it failed immediately. The error message is long and mentions DaemonSet-managed pods, but I didn't read it carefully — I just thought drain was broken. Always use `--ignore-daemonsets --delete-emptydir-data`. Every time. No exceptions.
>
> Subtle one: `k cordon` marks the node unschedulable but does NOT evict existing pods. I cordoned a node thinking it would move pods off it, then spent 5 minutes wondering why pods were still there. Cordon = "don't schedule new pods here." Drain = "evict everything and cordon."

<details>
<summary>Solution</summary>

```bash
# List nodes
k get nodes
# Pick a worker node, e.g., worker-1

# Cordon
k cordon worker-1
k get nodes
# worker-1 should show SchedulingDisabled

# Create deployment
k create deployment drain-test --image=nginx:1.27 --replicas=3

# Check pod placement
k get pods -o wide

# Drain
k drain worker-1 --ignore-daemonsets --delete-emptydir-data

# Verify eviction
k get pods -o wide
# All drain-test pods should be on other nodes

# Check node
k get pods -A --field-selector spec.nodeName=worker-1
# Only DaemonSet pods should remain

# Uncordon
k uncordon worker-1
k get nodes
# worker-1 should be Ready (no SchedulingDisabled)

# Scale up — new pods should land on worker-1 too
k scale deployment drain-test --replicas=6
k get pods -o wide
```

</details>
