# DaemonSet on every node

1. List the DaemonSets that already exist in the cluster, in all
   namespaces, and note how many pods each runs:

   `kubectl get daemonsets -A`{{exec}}

2. Create a DaemonSet named `monitoring-daemon` in the `default`
   namespace with image `nginx` and pod label `app=monitoring-agent`.

   There is no `kubectl create daemonset` command. Generate a
   Deployment skeleton, change `kind` to `DaemonSet`, remove `replicas`
   and `strategy`, and make `selector.matchLabels` equal to the
   template labels:

   `kubectl create deployment monitoring-daemon --image=nginx --dry-run=client -o yaml > ds.yaml`{{exec}}

   The result should look like this:

   ```yaml
   apiVersion: apps/v1
   kind: DaemonSet
   metadata:
     name: monitoring-daemon
   spec:
     selector:
       matchLabels:
         app: monitoring-agent
     template:
       metadata:
         labels:
           app: monitoring-agent
       spec:
         containers:
         - name: nginx
           image: nginx
   ```{{copy}}

3. Create it and check how many pods it created and on which nodes:

   `kubectl apply -f ds.yaml && kubectl get pods -l app=monitoring-agent -o wide`{{exec}}

   The control plane node is missing a pod. Find out why — describe the
   control plane node (`controlplane`) and look at its Taints:

   `kubectl describe node controlplane | grep -i taints`{{exec}}

4. Change the DaemonSet so its pods also run on the control plane
   node. Add a toleration for the control plane taint under
   `template.spec` in `ds.yaml`:

   ```yaml
   spec:
     template:
       spec:
         tolerations:
         - key: node-role.kubernetes.io/control-plane
           operator: Exists
           effect: NoSchedule
   ```{{copy}}

   `kubectl apply -f ds.yaml`{{exec}}

5. Verify there is exactly one `monitoring-daemon` pod on every node:

   `kubectl get pods -l app=monitoring-agent -o wide`{{exec}}

When done, click **CHECK**.
