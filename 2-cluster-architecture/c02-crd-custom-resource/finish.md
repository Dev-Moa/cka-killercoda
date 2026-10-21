<details>
<summary>Solution</summary>

```bash
# 1. existing CRDs and one of them in detail
kubectl get crd
kubectl get crd <name> -o yaml | grep -E "group:|scope:|shortNames|- name: v|served"

# 2. copy the docs example into a file, then create it
vi crd.yaml
```

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: crontabs.stable.example.com      # <plural>.<group>
spec:
  group: stable.example.com
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                cronSpec:
                  type: string
                image:
                  type: string
  scope: Namespaced
  names:
    plural: crontabs
    singular: crontab
    kind: CronTab
    shortNames:
    - ct
```

```bash
kubectl apply -f crd.yaml
kubectl api-resources | grep crontab

# 3. an object of the new kind
vi my-crontab.yaml
```

```yaml
apiVersion: stable.example.com/v1
kind: CronTab
metadata:
  name: my-new-cron-object
spec:
  cronSpec: "* * * * */5"
  image: my-awesome-cron-image
```

```bash
kubectl apply -f my-crontab.yaml

# 4. read it back
kubectl get ct
kubectl get crontab my-new-cron-object -o yaml
kubectl explain crontab.spec

# 5. deleting the CRD deletes every object of that kind
kubectl delete crd crontabs.stable.example.com
kubectl get ct
```

**Key insight:** a CRD only teaches the API server a new kind. It does
nothing by itself. An operator is a controller that watches those
objects and acts on them. Installing an operator is usually
`kubectl apply -f <its manifest>` or a Helm chart, and the CRDs come
with it. The exam asks you to inspect and create, not to write a
controller.

</details>
