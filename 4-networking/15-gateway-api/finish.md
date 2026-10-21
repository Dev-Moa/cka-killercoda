## What tripped me up

> The `parentRefs.name` in HTTPRoute must match the Gateway name EXACTLY. I had `web-gw` in the HTTPRoute but the Gateway was called `web-gateway`. No error — the HTTPRoute just never attached to anything. Traffic goes nowhere and there's no obvious indication why. I spent 10 minutes checking backend pods and service selectors when the problem was a one-word typo in parentRefs.
>
> Also: Gateway API won't work without a GatewayClass controller actually installed. On a fresh cluster there might be no GatewayClass at all. `k get gatewayclass` — if it's empty, you need to install a controller first. The exam environment should have one, but verify before writing YAML.

<details>
<summary>Solution</summary>

```bash
k create ns exercise-15

# Check GatewayClass
k get gatewayclass
# Note the name, e.g., "eg" for Envoy Gateway or "cilium" for Cilium
```

```yaml
# gateway.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web-gateway
  namespace: exercise-15
spec:
  gatewayClassName: eg    # replace with your GatewayClass name
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
```

```bash
# Deploy backend
k create deployment web -n exercise-15 --image=nginx:1.28 --replicas=2
k expose deployment web -n exercise-15 --port=80 --target-port=80 --name=web-svc
```

```yaml
# httproute.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
  namespace: exercise-15
spec:
  parentRefs:
  - name: web-gateway
    namespace: exercise-15
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: web-svc
      port: 80
```

```bash
k apply -f gateway.yaml
k apply -f httproute.yaml

# Check Gateway status
k get gateway web-gateway -n exercise-15
k get gateway web-gateway -n exercise-15 -o yaml | grep -A5 "conditions"

# Check HTTPRoute
k get httproute web-route -n exercise-15 -o yaml | grep -A5 "parents"
```

</details>
