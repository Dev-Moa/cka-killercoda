## What tripped me up

> **Replace vs Add Trap (Reading Comprehension):** ConfigMap has `tls_min_version=1.3`. Exam says "ADD support for TLS 1.2." My instinct: replace it with `1.2` — this breaks 1.3. Correct approach: Change `tls_min_version=1.2` (allows 1.2 through 1.3+) or add a list `supported_versions=[1.2,1.3]`. Always read "ADD support" vs "REPLACE" vs "UPDATE" carefully. Adding ≠ Replacing.
>
> **ConfigMap Changes Don't Auto-Reload (Most Critical Gotcha):** Edited ConfigMap and tested immediately — still saw TLS 1.3 only. ConfigMaps mounted in pods are snapshot at pod start time. Changes to ConfigMap don't propagate to existing pods automatically. Must restart: `k rollout restart deployment/<name>`. Forget this step and your fix appears broken.
>
> **Finding the TLS Config (Location Varies):** TLS settings might be in:
  - ConfigMap env var: `TLS_MIN_VERSION=1.3`
  - ConfigMap file: `/etc/config/tls.conf` with `minVersion: 1.3`
  - Deployment spec: `--tls-min-version=1.3` flag
  - Secret: if using cert files
  Always first: `k describe deployment <name>` to see where config comes from. Then `k get cm <name> -o yaml` or `k edit cm <name>` to modify it.
>
> **May 2026 Gotcha (TLS 1.3 Restrictions):** In k8s 1.35, some components enforce TLS 1.3 minimum by default (e.g., api-server defaults to `1.3` or `1.2-1.3`). Downgrading to support `1.0` or `1.1` might be blocked by admission webhooks or security policies. Always check what the minimum supported version actually is in k8s 1.35 — it's usually not below 1.2.
>
> **openssl s_client Syntax for Testing:** Command is: `echo | openssl s_client -connect <ip>:<port> -tls1_2 2>/dev/null | grep Protocol`
  - Missing `-connect` format: wrong syntax
  - Missing version flag (e.g., just `-tls` instead of `-tls1_2`): tries multiple versions, hard to know which one succeeded
  - Forgetting `2>/dev/null`: diagnostic output clutters result
  - Missing `echo |`: command hangs waiting for input
  Test both after restart to confirm both versions work.
>
> **Restart Timing Issues:** After `k rollout restart`, pods take 10-30 seconds to start (depends on image size, node load). Testing immediately might hit a pod that's still starting or old pod that's terminating. Wait for stable: `k get pod -w` until all pods are `Running` and check again.
>
> **Service Endpoint Changes After Restart:** When you restart a deployment, the service endpoints temporarily become empty (no ready pods). During this window, `curl` calls to the service fail. Clients see connection refused. This is normal — wait for new pods to be ready. This can appear like your fix broke things when it's just timing.

<details>
<summary>Solution</summary>

```bash
# 1. Find the service and ConfigMap
k get svc --all-namespaces
k get cm --all-namespaces

# 2. Check current TLS config
k get cm <name> -o yaml

# 3. Edit ConfigMap to add TLS 1.2
k edit cm <name>
# Find line like: tls_min_version: "1.3"
# Change to: supported_versions: ["1.2", "1.3"]
# Or if format is different, add TLS 1.2

# 4. Check if there's an env var that sets this
k describe deployment <deployment>
# Look for "Environment:" section

# 5. If config is in file mount, edit ConfigMap
# Then restart deployment

k rollout restart deployment/<deployment>

# 6. Wait for pod to be ready
k rollout status deployment/<deployment>

# 7. Portforward to test (if service is internal)
k port-forward svc/<service> <local-port>:<remote-port> &

# 8. Test TLS 1.2 connection
echo | openssl s_client -connect localhost:<port> -tls1_2 2>/dev/null | grep "Protocol"
# Should show: Protocol  : TLSv1.2

# 9. Test TLS 1.3 still works
echo | openssl s_client -connect localhost:<port> -tls1_3 2>/dev/null | grep "Protocol"
# Should show: Protocol  : TLSv1.3

# 10. Or use curl
curl -k --tlsv1.2 https://localhost:<port>
curl -k --tlsv1.3 https://localhost:<port>
```

</details>
