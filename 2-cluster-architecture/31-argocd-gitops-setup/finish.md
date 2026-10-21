## What tripped me up

> I installed Argo CD with CRDs included and then the Application CRD already existed. Then when I tried to apply the Application manifest, it didn't have the right fields. Argo CD has a specific Application spec structure that's different from regular Deployments. The exam said "generate WITHOUT CRDs" — follow instructions exactly. Also: the Git repository URL matters — wrong URL means Application stays out-of-sync. Test the repo URL is accessible BEFORE applying the Application.

<details>
<summary>Solution</summary>

```bash
# 1. Create Argo CD namespace
k create namespace argocd

# 2. Install Argo CD (check https://argo-cd.readthedocs.io/en/stable/getting_started/)
# Use specific version, e.g., v2.10.3
k apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.10.3/manifests/install.yaml

# Note: Don't apply -f manifests/crds.yaml separately

# 3. Wait for Argo CD to be ready
k wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# 4. Create an Application manifest (GitOps)
cat <<EOF > application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    targetRevision: HEAD
    path: guestbook
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

# 5. Apply the Application
k apply -f application.yaml

# 6. Watch sync status
k get application -n argocd -w

# 7. Check deployment status
k get pod -n default

# 8. Verify resources created by Argo CD
k get all -n default

# 9. Access Argo CD UI (optional)
k port-forward -n argocd svc/argocd-server 8080:443
# Navigate to https://localhost:8080
# Default password: admin / (stored in secret)
# Get password: k get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d

# 10. View application sync status
k get application my-app -n argocd -o jsonpath='{.status.sync.status}'
# Output: Synced
```

References:
- Argo CD Docs: https://argo-cd.readthedocs.io/
- Application CRD: https://argo-cd.readthedocs.io/en/stable/declarative-setup/

</details>
