# cka-killercoda

Killercoda scenarios for the CKA exercises that need SSH to a node
(static pods, kubeadm upgrades, etcd, kubelet work). The local CK-X
labs host everything else. One folder = one scenario.

## Connect to Killercoda

1. Sign in at killercoda.com, open your profile -> Scenarios ->
   **Add Repository**.
2. Repository: `Dev-Moa/cka-killercoda`, branch `main`.
3. Every push to `main` updates the scenarios.

## Scenario layout

```
<exercise>/
├── index.json          # title, steps, backend image
├── intro.md            # shown before step 1
├── background.sh       # runs hidden when the environment starts
├── step<N>/text.md     # the exercise text
├── step<N>/verify.sh   # CHECK button script (exit 0 = pass)
└── finish.md           # shown after the last step
```

See https://killercoda.com/creators for the full docs.

## Scenarios

| folder | exercise | image |
| --- | --- | --- |
| `10-static-pod/` | static pod in the kubelet manifest directory | `kubernetes-kubeadm-2nodes` |
