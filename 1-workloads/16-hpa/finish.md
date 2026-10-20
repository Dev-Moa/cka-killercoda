# HPA - done

The exam facts from this exercise:

- HPA shows `<unknown>/50%` when the Deployment has no CPU request — always set `resources.requests.cpu` on pods that need autoscaling.
- The metric target must be `type: Utilization` with `averageUtilization: 50` — `AverageValue` never scales for CPU.
- `kubectl autoscale deployment load-app -n exercise-16 --cpu-percent=50 --min=1 --max=5` creates the correct HPA in one line.
- No metrics-server means no HPA: `kubectl top nodes` must return data (allow about a minute after the cluster starts).
- Scale-down after the load stops takes about 5 minutes on purpose — do not wait for it in the exam.
- Utilization is a percentage of the requested CPU: a pod that requests `50m` and uses `25m` is at 50%.

The exercise is based on the HPA note in
`notes/4-application-lifecycle-management/44` and exercise 16 in
`cka-prep/exercises/1-workloads/`.
