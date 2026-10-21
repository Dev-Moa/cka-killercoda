# Exercise 27 — CNI Installation (Calico/Tigera Operator)

Install a full CNI plugin using the Tigera Operator for Calico, including networking and security policies. Essential for multi-node clusters.

## Tasks

1. Verify cluster CIDR from kube-controller-manager
2. Install Tigera Operator:
   - Apply operator manifest
   - Wait for operator deployment
3. Create custom resource for Calico configuration:
   - Set cluster CIDR matching kube-controller-manager
   - Configure networking mode (VXLAN or BGP)
4. Apply Calico installation manifest
5. Wait for calico-system pods to be Ready
6. Verify node networking is operational:
   - Nodes can ping each other
   - Pods on different nodes can communicate
7. Test NetworkPolicy blocking works

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- Get cluster CIDR: `k describe cm kubeadm-config -n kube-system | grep pod-network-cidr`
- Alternative: `ps aux | grep kube-controller-manager | grep cidr`
- Tigera docs: `https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises`
- Wait for pods: `k get pods -n calico-system -w`
- Test pod networking: `k run test --image=busybox:1.36 --rm -it -- ping <pod-ip>`

</details>

## Verify

```bash
# Operator is running
k get deployment -n tigera-operator

# Calico system pods are Ready
k get pods -n calico-system

# Nodes have calico agents
k get pods -n calico-system -l k8s-app=calico-node

# Test pod networking (create pods on different nodes)
k run pod1 --image=busybox:1.36 --rm -it -- sleep 3600
k run pod2 --image=busybox:1.36 --rm -it -- sleep 3600
# From pod1: ping pod2 IP (should succeed)

# NetworkPolicy works
k apply -f <networkpolicy>
```

When done, click **CHECK**.
