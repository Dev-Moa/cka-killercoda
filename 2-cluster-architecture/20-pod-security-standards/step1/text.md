# Exercise 20 — Pod Security Standards

Implement Pod Security Standards (PSS) at the namespace level to enforce security policies. This exercise covers enforcing restricted, baseline, and restricted security contexts on pods.

## Conventions

Understanding PSS troubleshooting trap patterns:

- **Primary Trap:** Wrong label format (`pod-security` vs `pod-security.kubernetes.io`) — silently ignored, no error
- **Secondary Trap (Gotcha):** PSS labels applied but pod already running — doesn't retroactively enforce
- **Validation Criteria:** Your answer is correct if:
  - Restricted namespace rejects non-compliant pods with error message (not Pending)
  - Baseline namespace allows configurable pods but rejects privileged containers
  - Audit mode allows pods but shows annotations in `k describe pod`
  - All label formats use full `pod-security.kubernetes.io/` prefix
- **Scoring:** Full credit for all 3 modes working + correct label syntax. Partial for partial enforcement.

## Context

Pod Security Standards replaced Pod Security Policies in Kubernetes 1.25+. They enforce security constraints at the namespace level through labels. The CKA tests your ability to:
- Apply PSS labels to namespaces
- Understand the three levels: restricted, baseline, and privileged
- Diagnose when pods violate security policies
- Use audit and warn modes for testing before enforcement

In Kubernetes 1.35, Pod Security Standards are part of the standard admission control process.

## Tasks

1. Create a namespace called `exercise-20`
2. Label it with Pod Security Standards at `restricted` level in `enforce` mode
3. Attempt to run a pod with a privileged container in `exercise-20`—it should be rejected
4. Create a second namespace `exercise-20-baseline` with `baseline` PSS level
5. Run a pod with `runAsNonRoot: true` in the baseline namespace—it should succeed
6. Run a pod with `privileged: true` in the baseline namespace—it should be rejected
7. Create a third namespace `exercise-20-audit` with `restricted` level but in `audit` mode
8. Run a privileged pod in audit mode—it should succeed but be logged as a violation
9. Check the audit annotations on the pod that ran in audit mode

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- Namespace labels for PSS use format: `pod-security.kubernetes.io/enforce=restricted`
- Three modes: `enforce` (deny), `audit` (allow but log), `warn` (allow but show warning)
- Pod security levels: `privileged` (no restrictions), `baseline` (minimal restrictions), `restricted` (modern hardening)
- `k label ns <namespace> pod-security.kubernetes.io/enforce=restricted` to add PSS labels
- `k get pods -o yaml` shows audit annotations in `metadata.annotations` when violations occur
- A "restricted" level pod must have: `runAsNonRoot=true`, `allowPrivilegeEscalation=false`, `readOnlyRootFilesystem=true`

</details>

## Verify

```bash
# Create restricted namespace
k create ns exercise-20
k label ns exercise-20 pod-security.kubernetes.io/enforce=restricted

# Try to run privileged pod (should fail)
k run rogue --image=nginx:1.28 --privileged -n exercise-20
# Expected: Pod is rejected with error

# Create baseline namespace
k create ns exercise-20-baseline
k label ns exercise-20-baseline pod-security.kubernetes.io/enforce=baseline

# Try baseline pod with non-root (should succeed)
k run safe-pod --image=nginx:1.28 -n exercise-20-baseline
k get pods -n exercise-20-baseline

# Try privileged in baseline (should fail)
k run priv-pod --image=nginx:1.28 --privileged -n exercise-20-baseline
# Expected: Pod rejected

# Create audit namespace
k create ns exercise-20-audit
k label ns exercise-20-audit pod-security.kubernetes.io/audit=restricted

# Run pod in audit mode (should succeed but log violation)
k run audit-pod --image=nginx:1.28 -n exercise-20-audit
k describe pod audit-pod -n exercise-20-audit
# Check annotations for security violations
```

When done, click **CHECK**.
