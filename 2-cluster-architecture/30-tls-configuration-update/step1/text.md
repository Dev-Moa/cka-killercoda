# Exercise 30 — TLS Configuration Update (Cipher Support)

Update TLS configuration to support additional protocol versions for backward compatibility. Tests ConfigMap modification and service restart.

## Conventions

TLS configuration troubleshooting involves configuration and restart traps:

- **Primary Trap:** ConfigMap edited but pod not restarted (config changes don't auto-reload)
- **Secondary Trap (Gotcha):** Conflating min-version with supported-versions (replacing vs adding support)
- **Validation Criteria:** Your fix is correct if:
  - `k edit cm` shows both TLS 1.2 and 1.3 in configuration
  - Pod is running after restart (check timestamps with `k get pod -owide`)
  - `openssl s_client -connect <ip>:<port> -tls1_2` shows "Protocol: TLSv1.2"
  - `openssl s_client -connect <ip>:<port> -tls1_3` shows "Protocol: TLSv1.3"
  - Both protocols work (don't break existing functionality)
- **Scoring:** Full credit for both TLS versions working + ConfigMap correct. Partial for config edit without restart.

## Tasks

1. A service currently supports only TLS 1.3
2. Add support for TLS 1.2 (make both available)
3. Update configuration file or ConfigMap:
   - Add TLS 1.2 to supported protocols
   - Keep TLS 1.3 enabled
4. ConfigMap is mounted in Deployment as env var or config file
5. Restart Deployment to apply changes
6. Verify service accepts TLS 1.2 connections:
   - Use `openssl s_client -connect <service> -tls1_2`
   - Or curl with explicit TLS 1.2
7. Verify TLS 1.3 still works

## Key Learning

- TLS configuration often in ConfigMaps
- Adding vs replacing: exam specifies "ADD support" (don't remove existing)
- Service restart may be needed after config change
- TLS negotiation must support minimum version
- Testing TLS versions requires understanding openssl commands

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- Edit ConfigMap: `k edit cm <name>`
- Find TLS setting (could be `tlsVersion`, `tls1.3Min`, etc.)
- After edit, restart pod: `k rollout restart deployment/<name>`
- Test TLS 1.2: `openssl s_client -connect <ip>:<port> -tls1_2`
- Verify version in output: "Protocol  : TLSv1.2"
- Test TLS 1.3: `openssl s_client -connect <ip>:<port> -tls1_3`

</details>

## Verify

```bash
# ConfigMap has both TLS 1.2 and 1.3
k get cm <name> -o yaml | grep -i tls

# Deployment is running after restart
k get deployment <name>

# Service endpoint is responding
k get svc <name> -o wide

# Test TLS 1.2
echo | openssl s_client -connect <ip>:<port> -tls1_2 2>/dev/null | grep Protocol
# Output: Protocol  : TLSv1.2

# Test TLS 1.3
echo | openssl s_client -connect <ip>:<port> -tls1_3 2>/dev/null | grep Protocol
# Output: Protocol  : TLSv1.3
```

When done, click **CHECK**.
