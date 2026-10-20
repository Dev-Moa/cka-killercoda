# Taint, tolerate, restore

Taint a node so it repels pods, then let one pod in with a toleration.
This tests that you know which side the taint goes on (the node) and
which side the toleration goes on (the pod), and that you can remove a
taint.

Do this question last. Its end state leaves the worker node tainted
(`spray=mortein:NoSchedule`), which stops new pods from the other
questions from scheduling.

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

When done, click CHECK.
