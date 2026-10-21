<details>
<summary>Solution</summary>

```bash
# 1. find the flag, then read the cert
grep kubelet-client-certificate /etc/kubernetes/manifests/kube-apiserver.yaml
# --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt
openssl x509 -in /etc/kubernetes/pki/apiserver-kubelet-client.crt -text -noout
# Subject: CN=kube-apiserver-kubelet-client · Issuer: CN=kubernetes · Not After: <date>

# 2. every kubeadm cert at once
kubeadm certs check-expiration

# 3. key + CSR for the new user (the CN becomes the username)
openssl genrsa -out jane.key 2048
openssl req -new -key jane.key -subj "/CN=jane" -out jane.csr

# 4. the CSR object: base64 the file on one line
cat jane.csr | base64 -w 0
```

```yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: jane
spec:
  request: <base64 here>
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
```

```bash
kubectl create -f csr.yaml
kubectl get csr                                              # jane Pending

# 5. approve and extract the signed cert
kubectl certificate approve jane
kubectl get csr jane                                         # Approved,Issued
kubectl get csr jane -o jsonpath='{.status.certificate}' | base64 -d > jane.crt

# 6. a kubeconfig for jane, then prove authn works and authz doesn't
CA=$(grep certificate-authority /etc/kubernetes/admin.conf | awk '{print $2}')
SERVER=$(grep server /etc/kubernetes/admin.conf | awk '{print $2}')
kubectl config set-cluster exam --server=$SERVER --certificate-authority=$CA --kubeconfig /tmp/jane.kubeconfig
kubectl config set-credentials jane --client-certificate=jane.crt --client-key=jane.key --kubeconfig /tmp/jane.kubeconfig
kubectl config set-context jane@exam --cluster=exam --user=jane --kubeconfig /tmp/jane.kubeconfig
kubectl config use-context jane@exam --kubeconfig /tmp/jane.kubeconfig
kubectl --kubeconfig /tmp/jane.kubeconfig get pods           # forbidden — the cert works, RBAC is missing
```

**Key insight:** viewing a cert = grep the manifest flag, then openssl.
A new user = key + CSR + approve + extract — the API server is not the
CA; the kube-controller-manager signs CSRs with the cluster CA. A cert
that passes authentication but fails authorization is the success state
for a brand-new user.

</details>
