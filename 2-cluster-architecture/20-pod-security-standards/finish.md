## What tripped me up

> **PSS Label Format Trap (Most Common Mistake):** I wrote `pod-security/enforce=restricted` but it should be `pod-security.kubernetes.io/enforce=restricted` (full path with `.io`). The typo was silently ignored — no error, the label just didn't apply. The namespace stayed in default (permissive) mode. Always double-check with `k describe ns <namespace>` to verify labels actually exist. PSS mistakes often fail silently.
>
> **Retroactive Enforcement Trap:** I labeled a namespace with `enforce=restricted`, then a non-compliant pod was already running. I expected kubectl to reject it retroactively — it didn't. PSS labels only apply to NEW pods. Already-running pods keep running. You must delete and re-create to test. This is a common exam gotcha: the policy looks wrong because old pods don't get enforced.
>
> **Audit vs Enforce Mode Confusion:** In `audit` mode, pods run even if they violate policies. The difference: `audit` pods succeed but get annotated, `enforce` pods are rejected outright. I thought audit mode was broken because the non-compliant pod succeeded. That's correct behavior — audit is observe-only. Check: `k describe pod <name> | grep security` for violations in annotations.
>
> **May 2026 Gotcha (PSS Versions):** In k8s 1.35, PSS levels are tied to specific Kubernetes API versions in the audit output. When checking audit logs, violations show a k8s version (`1.35.1`). If your audit policy and actual cluster version mismatch, some `restricted` requirements might not be enforced uniformly. Always check: `k version` to ensure cluster version matches your PSS policy expectations.
>
> **Security Context Inheritance Trap:** A pod with `securityContext.runAsNonRoot: true` at pod level can still run a container with `runAsRoot` if the container's securityContext is `runAsUser: 0`. Pod-level settings don't automatically cascade to all containers. For `restricted` enforcement, you need both pod AND container-level security contexts correct.
>
> **Namespace Deletion Cascades:** When you `k delete ns <namespace-with-pss>`, the pods in it are deleted first, then labels are removed. If you need to test label changes, it's cleaner to re-label an existing namespace rather than delete/re-create (faster for exam practice).
>
> **Three Modes Interaction:** If a namespace has all three labels (`enforce`, `audit`, `warn`), they apply in order: deny if `enforce` rejects it, then audit if allowed, then warn. Don't mix all three unless testing — audit+enforce in one namespace creates confusing logs.

<details>
<summary>Solution</summary>

```bash
# Create and label namespaces with PSS
k create ns exercise-20
k label ns exercise-20 pod-security.kubernetes.io/enforce=restricted

k create ns exercise-20-baseline
k label ns exercise-20-baseline pod-security.kubernetes.io/enforce=baseline

k create ns exercise-20-audit
k label ns exercise-20-audit \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted

# Test restricted enforcement
# This command will fail:
kubectl run restricted-test --image=nginx:1.28 -n exercise-20 --dry-run=server
# Error: pods "restricted-test" is forbidden: violates PodSecurityPolicy: ...

# Create compliant pod for restricted namespace
cat <<EOF | k apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  namespace: exercise-20
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
  containers:
  - name: nginx
    image: nginx:1.28
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
    volumeMounts:
    - name: tmp
      mountPath: /tmp
    - name: cache
      mountPath: /var/cache/nginx
  volumes:
  - name: tmp
    emptyDir: {}
  - name: cache
    emptyDir: {}
EOF

# Test baseline
kubectl run baseline-pod --image=nginx:1.28 -n exercise-20-baseline
k get pods -n exercise-20-baseline

# Test audit mode
kubectl run audit-test --image=nginx:1.28 -n exercise-20-audit
k describe pod audit-test -n exercise-20-audit
# Look for pod-security.kubernetes.io/restricted annotation showing violations

# Verify labels were applied correctly
k get ns exercise-20 exercise-20-baseline exercise-20-audit -o json | jq '.items[].metadata.labels'
```

</details>
