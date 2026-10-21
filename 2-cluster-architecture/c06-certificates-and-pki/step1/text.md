# Exercise C06 — Certificates and PKI

kubeadm creates every certificate for you — the exam only asks you to
VIEW them (grep the flag, read with `openssl`) and to process
CertificateSigningRequests when a new user joins. Needs a kubeadm
control plane node you can SSH to.

## Tasks

Run everything on the control plane node.

1. Find which certificate the API server uses to talk to the kubelets:
   grep its manifest for the cert flag, then view that certificate with
   `openssl`. Read its Subject CN, Issuer, and expiry (`Not After`).
2. Check the expiry of every kubeadm certificate at once:
   `kubeadm certs check-expiration`.
3. Make a key and a CSR for a new user `jane`:
   `openssl genrsa -out jane.key 2048`, then
   `openssl req -new -key jane.key -subj "/CN=jane" -out jane.csr`.
4. Create a CertificateSigningRequest object for that CSR. It must show
   as Pending in `kubectl get csr`.
5. Approve the request, then extract the signed certificate from the
   object into `jane.crt`.
6. Build a kubeconfig `/tmp/jane.kubeconfig` for jane (cluster server +
   CA from `/etc/kubernetes/admin.conf`, user jane with her cert and
   key) and prove the certificate works:
   `kubectl --kubeconfig /tmp/jane.kubeconfig get pods` — it must fail
   with *forbidden*, not with a certificate error. Authenticated but
   no permissions is the expected end state.

## Hints

<details>
<summary>Stuck? Click to reveal hints</summary>

- The CSR must be base64 on ONE line: `cat jane.csr | base64 -w 0`.
- The two keys that make or break the CSR object:
  `signerName: kubernetes.io/kube-apiserver-client` and
  `usages: [client auth]` — get the skeleton from the docs page.
- Approve: `kubectl certificate approve jane`. The signed cert is
  base64 in `status.certificate`:
  `kubectl get csr jane -o jsonpath='{.status.certificate}' | base64 -d > jane.crt`.
- The CA file for the kubeconfig lives at `/etc/kubernetes/pki/ca.crt`
  (read it from `admin.conf`).
- `openssl x509 -in <file> -text -noout` — it is `x509`, and `-noout`
  has two o's.

</details>

## Verify

```bash
openssl x509 -in /etc/kubernetes/pki/apiserver-kubelet-client.crt -text -noout | grep -E "Subject:|Issuer:|Not After"   # task 1
kubeadm certs check-expiration                               # task 2: a table of expiries
kubectl get csr jane                                         # task 5: CONDITION Approved,Issued
kubectl --kubeconfig /tmp/jane.kubeconfig get pods           # task 6: Error: ... forbidden
```

When done, click **CHECK**.
