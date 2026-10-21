# Exercise T04 — Monitoring Metrics

The Metrics Server collects CPU and memory from each node's kubelet
into memory, and `kubectl top` reads it. The exam checks you can read
node and pod metrics — and that you know a fresh cluster needs about a
minute before top returns values.

## Tasks

1. Confirm the Metrics Server runs:
   `kubectl get pods -n kube-system | grep metrics`.
2. Try `kubectl top node`. If it errors, wait and retry — a fresh
   cluster takes about a minute to start reporting.
3. Read the output: node name, CPU%, CPU(m), MEMORY%, MEMORY(Mi).
4. Create a deployment named `load` with image `nginx` in the
   `default` namespace. Once its pod is Running, run `kubectl top pod`
   and find the pod's CPU and memory.

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- Metrics Server is in-memory only — no history, that is what
  Prometheus-type tools are for.
- The metrics come from each kubelet's cAdvisor subcomponent.
- `kubectl top` errors right after cluster start are normal; check
  that the metrics-server pod is Running, then wait.

</details>

## Verify

```bash
kubectl top node             # a table, CPU% and MEMORY% columns with values
kubectl top pod              # the load pod with CPU and memory numbers
```

When done, click **CHECK**.
