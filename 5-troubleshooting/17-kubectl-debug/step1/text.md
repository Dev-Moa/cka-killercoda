# Exercise 17 — kubectl debug: Pod and Node

Use `kubectl debug` to troubleshoot running pods and access node-level resources. This is GA in v1.35 and directly relevant to CKA troubleshooting tasks.

## Conventions

Before debugging, understand the trap architecture:

- **Primary Trap:** Debug container started without `--target` (isolated namespace instead of shared)
- **Secondary Trap (Gotcha):** Node debug without `chroot /host` (sees container filesystem, not node)
- **Validation Criteria:** Your debug session shows:
  - Pod debug: processes from target container visible in debug pod
  - Node debug: node filesystem mounted at `/host`, kubelet systemd status accessible
  - Both: no errors when listing processes or checking services
- **Scoring:** Full credit for successful debug + root cause identification. Partial for debug success alone.

## Tasks

### Part A: Debug a pod

1. Create a namespace called `exercise-17`
2. Create a pod named `broken-app` with image `nginx:1.27`
3. Attach a debug container to the running pod using `kubectl debug`:
   - Image: `busybox:1.36`
   - Target the `broken-app` container to share process namespace
4. From inside the debug container, list the processes (you should see the nginx process)
5. Check the filesystem and network from the debug container
6. Exit the debug session

### Part B: Debug a node

7. Run `kubectl debug` against a node to get a shell with host filesystem access
8. Use `chroot /host` to access the real node root
9. Check kubelet status from the debug session
10. Exit the debug session

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- Pod debug: `k debug <pod> -it --image=busybox:1.36 --target=<container>`
- Node debug: `k debug node/<node-name> -it --image=busybox:1.36`
- The `--target` flag shares process namespace with the target container
- Node debug mounts the host filesystem at `/host`
- Use `chroot /host` to run node commands directly

</details>

## Verify

```bash
# Part A: process list should show nginx
# Inside debug container:
ps aux

# Part B: kubelet check
# Inside node debug (after chroot /host):
systemctl status kubelet
```

When done, click **CHECK**.
