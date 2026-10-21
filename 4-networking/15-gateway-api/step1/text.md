# Exercise 15 — Gateway API: Gateway and HTTPRoute

Gateway API is GA in v1.35 and replaces classic Ingress for modern traffic management. Set up a Gateway and route HTTP traffic to a backend service.

## Tasks

1. Create a namespace called `exercise-15`
2. Verify a GatewayClass exists in the cluster (depends on your CNI/controller)
3. Create a Gateway named `web-gateway` in namespace `exercise-15`:
   - Reference the existing GatewayClass
   - Listen on port 80, protocol HTTP
4. Create a Deployment named `web` with image `nginx:1.28` and 2 replicas
5. Expose it with a ClusterIP Service named `web-svc` on port 80
6. Create an HTTPRoute named `web-route` that:
   - References `web-gateway` as the parent
   - Matches path prefix `/`
   - Routes to `web-svc` on port 80
7. Verify the Gateway status shows `Programmed: True`
8. Verify the HTTPRoute is attached to the Gateway

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- `k get gatewayclass` to find the available class
- The Gateway `listeners[].protocol` is `HTTP`, not `TCP`
- HTTPRoute `parentRefs` must match the Gateway name and namespace
- Check status: `k get gateway web-gateway -n exercise-15 -o yaml`
- If no GatewayClass is installed, use Envoy Gateway or Cilium

</details>

## Verify

```bash
# Gateway ready
k get gateway web-gateway -n exercise-15

# HTTPRoute accepted
k get httproute web-route -n exercise-15

# Backend pods running
k get pods -n exercise-15
```

When done, click **CHECK**.
