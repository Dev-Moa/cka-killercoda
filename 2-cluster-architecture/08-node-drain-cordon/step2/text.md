# Exercise 08 — Node Drain and Cordon

Drain a worker node for maintenance, then bring it back. This tests your understanding of pod eviction, DaemonSets, and scheduling.

## Tasks

7. Uncordon the node
8. Scale the deployment to 6 replicas and verify pods get scheduled on the uncordoned node

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

You honestly don't need hints for this one. `k drain --help` tells you everything. The two flags you always need are `--ignore-daemonsets` and `--delete-emptydir-data`.

</details>

## Verify

```bash
# After cordon
k get nodes
# Worker should show SchedulingDisabled

# After drain
k get pods -o wide
# No pods on the drained node (except DaemonSets)

# After uncordon + scale
k get pods -o wide
# Pods should spread across nodes again
```

When done, click **CHECK**.
