# Exercise 31 — Argo CD Setup (GitOps Deployment)

Install Argo CD and configure it to deploy applications from a Git repository. Tests GitOps concepts and custom resource management.

## Tasks

1. Install Argo CD in cluster:
   - Create `argocd` namespace
   - Apply Argo CD manifests (WITHOUT CRDs if specified)
2. Generate Kubernetes manifest template:
   - Define an Application resource
   - Point to a Git repository
   - Specify deployment target namespace
   - Do NOT install CRDs — let Argo CD install them
3. Save generated Application manifest to file
4. Verify Argo CD server is Running
5. Apply the Application manifest
6. Verify application deployment syncs
7. Create a port-forward to Argo CD UI (optional testing)

## Key Learning

- GitOps: cluster state matches Git repository
- Argo CD Application resource is a CRD
- CRDs are NOT in base manifests — error if you apply before Argo CD
- Application must specify repoURL, path, destination
- Exam tests CRD understanding and GitOps workflow

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- Argo CD install: `k create ns argocd` + apply base manifests
- Don't install CRDs separately — Argo CD operator does it
- Wait for server to start: `k get pod -n argocd -l app.kubernetes.io/name=argocd-server`
- Application spec needs: `repoURL`, `path`, `destination.namespace`
- Sync status: `k get application -A`

</details>

## Verify

```bash
# Argo CD is running
k get pod -n argocd

# Argo CD server is accessible
k port-forward -n argocd svc/argocd-server 8080:443

# Application resource exists and is in sync
k get application -A

# Get application sync status
k get application -n <namespace> <app-name> -o jsonpath='{.status.sync.status}'
# Should show: Synced

# Check deployed resources
k get deployment,service -n <app-namespace>
```

When done, click **CHECK**.
