# Taint, tolerate, restore

The cluster has a control plane node and one worker node.

1. Find the name of the worker node.
2. Check whether the worker node has any taints.
3. Taint the worker node with key `spray`, value `mortein`, effect
   `NoSchedule`.
4. Create a pod named `mosquito` with image `nginx` in the `default`
   namespace. Check its status and note why it stays Pending.
5. Create a pod named `bee` with image `nginx` in the `default`
   namespace that tolerates the taint from step 3. Verify it runs on the
   worker node.
6. Check the taints on the control plane node. Remove the `NoSchedule`
   taint there and watch what happens to `mosquito` — note which node it
   lands on.
7. Put the control plane taint back.

End state: `mosquito` Running on the control plane node, `bee` Running
on the worker node, and both taints present.

Useful commands:

`kubectl taint nodes node01 spray=mortein:NoSchedule`{{exec}}

`kubectl taint nodes controlplane node-role.kubernetes.io/control-plane:NoSchedule-`{{exec}}

`kubectl taint nodes controlplane node-role.kubernetes.io/control-plane:NoSchedule`{{exec}}

For `bee`, generate the pod YAML first, then add this under `spec`, at
the same level as `containers`:

```yaml
tolerations:
- key: spray
  operator: Equal
  value: mortein
  effect: NoSchedule
```{{copy}}

When done, click CHECK.
