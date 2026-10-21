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

Rule: the step text is a verbatim copy of the exercise's own file
(`CKA-Certified-Kubernetes-Administrator/exercises/<id>/README.md`, or
`cka-prep/exercises/...` for the W exercises): Context/Tasks/Hints/
Verify into the step, What tripped me up + Solution into `finish.md`,
and only a `When done, click **CHECK**.` line added. No rewording, no
invented prose, no `{{exec}}`/`{{copy}}` decorations.
Validators check objects and specs only — port the exercise's Verify
section and the graded fields. Never assert on log text or other
free-form content the candidate writes.

## Scenarios

Scenarios are grouped by domain folder (a subdirectory is a scenario
group in Killercoda). All run on the `kubernetes-kubeadm-2nodes` image:
root on `controlplane`, `node01` reachable via `ssh node01`.

### `1-workloads/` — Domain 1: Workloads & Scheduling

| folder | exercise |
| --- | --- |
| `01-pod-basics/` | pod with requests, limits, labels |
| `02-multi-container-pod/` | multi-container pod with a native sidecar |
| `03-configmap-secret/` | ConfigMap & Secret into env and mounts |
| `06-deployment-rollout/` | rolling update, rollout history, rollback |
| `07-statefulset/` | StatefulSet + headless Service |
| `10-static-pod/` | static pod in the kubelet manifest directory |
| `16-hpa/` | Horizontal Pod Autoscaler |
| `21-jobs-cronjobs/` | Jobs & CronJobs |
| `22-priorityclass/` | PriorityClass + preemptionPolicy |
| `23-resource-requests-tuning/` | fix oversubscribed requests |
| `24-priorityclass-patch/` | patch a PriorityClass into a Deployment |
| `w01-taints-and-tolerations/` | taints & tolerations |
| `w02-node-selectors-and-affinity/` | nodeSelector & node affinity |
| `w03-daemonset/` | DaemonSet with control-plane toleration |
