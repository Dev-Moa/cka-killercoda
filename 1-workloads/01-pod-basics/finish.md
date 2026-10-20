# Pod Basics - done

The exam facts from this exercise:

- Always set the namespace first: `kubectl config set-context --current
  --namespace exercise-01`. A pod created in `default` scores zero points.
- `kubectl run` cannot set resources. Generate the YAML with `kubectl run
  web --image=nginx:1.27 --labels=app=web,tier=frontend --dry-run=client
  -o yaml > web.yaml`, edit it, then apply.
- Resources go under `spec.containers[0].resources`: requests `64Mi`
  memory and `100m` CPU, limits `128Mi` memory and `250m` CPU.
- Add a label to a running pod: `kubectl label pod web version=v1`.
- Remove a label with a minus suffix: `kubectl label pod web tier-`.
- Check labels and IP: `kubectl get pod web --show-labels` and
  `kubectl get pod web -o wide`.

The exercise is based on exercise 01 in `cka-prep/exercises/1-workloads/`.
