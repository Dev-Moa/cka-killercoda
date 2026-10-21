## What tripped me up

> I forgot to check the actual cluster CIDR before installing Calico. Installed with default 192.168.0.0/16 but my cluster used 10.0.0.0/8. No inter-node networking worked. Pods on different nodes couldn't reach each other. Had to uninstall and reinstall with correct CIDR. Always grep the kube-controller-manager first. Also: Tigera operator takes time to start — don't panic if calico pods aren't running immediately. Give it 2-3 minutes.

## Key Learning

- CNI is required for pod networking between nodes
- Tigera Operator is production-grade Calico installation
- Cluster CIDR alignment is critical — mismatch breaks networking
- Exam provides the Tigera installation link
- Installation can take 2-3 minutes

<details>
<summary>Solution</summary>

```bash
# 1. Get cluster CIDR
k describe cm kubeadm-config -n kube-system | grep -i cidr
# Output: pod-network-cidr=10.244.0.0/16

# 2. Download Tigera operator
curl https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml -o tigera-operator.yaml

# 3. Install operator
k apply -f tigera-operator.yaml

# 4. Wait for operator to be ready
k wait --for=condition=available --timeout=300s deployment/tigera-operator -n tigera-operator

# 5. Create Calico Installation resource with correct CIDR
cat <<EOF | k apply -f -
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
    - blockSize: 26
      cidr: 10.244.0.0/16  # Must match your cluster CIDR
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
  variant: Calico
pointerSize: Felix
EOF

# 6. User custom resource (if needed)
# Usually not needed unless Tigera docs specify

# 7. Wait for Calico to be ready
k wait --for=condition=available --timeout=300s deployment -n calico-system -l k8s-app=calico-node

# 8. Check installation
k get pods -n calico-system
# Should show calico-node, calico-kube-controllers, calico-typha

# 9. Test networking
k run test1 --image=busybox:1.36 -- sleep 3600
k run test2 --image=busybox:1.36 -- sleep 3600

# Get IPs
POD1=$(k get pod test1 -o jsonpath='{.status.podIP}')
POD2=$(k get pod test2 -o jsonpath='{.status.podIP}')

# Test connectivity
k exec deploy/test1 -- ping -c 1 $POD2
# Should succeed
```

Reference: https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises

</details>
