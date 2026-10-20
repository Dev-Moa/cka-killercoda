# Resource requests tuning

Resource requests decide where a pod can run: the scheduler only
places a pod on a node that has the requested memory and CPU free.
When requests are set too high, pods stay Pending even though they
would actually use very little. The fix is to check the node's real
Allocatable capacity, then lower the requests until all replicas fit.
The exam trick: never apply a fixed overhead rule — calculate from
what the node actually has free.

A Deployment named `web` in namespace `exercise-23` has 3 replicas,
but every pod is Pending. The resource requests were set to impossible
values on purpose, so no node can fit them. Diagnose the failure, then
lower the requests so all 3 pods schedule and run. Keep the nginx
image.

1. Describe one Pending pod in namespace `exercise-23` and read its
   Events — which resource is insufficient?

2. Describe a node and compare its Allocatable capacity with what the
   pods request.

3. Update the Deployment `web` with realistic memory and CPU requests.

4. Verify all 3 pods are Running.

Remember: a request is a promise the scheduler must keep — if a pod
asks for more than a node can give, it stays Pending no matter how
little it actually uses.

When all 3 pods are Running, click **CHECK**.
