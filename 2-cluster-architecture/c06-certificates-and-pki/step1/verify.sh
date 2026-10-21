#!/bin/bash
# C06: CSR jane Approved and signed, jane's kubeconfig authenticates but has no permissions.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# Check 1: CSR object jane exists
name=$(kubectl get csr jane -o jsonpath='{.metadata.name}' 2>/dev/null)
if [ "$name" = "jane" ]; then
  echo "PASS 1: CSR jane exists"
else
  echo "FAIL 1: CSR jane not found (name=${name:-not found})"
  fail=1
fi

# Check 2: signerName is the kube-apiserver-client signer
signer=$(kubectl get csr jane -o jsonpath='{.spec.signerName}' 2>/dev/null)
if [ "$signer" = "kubernetes.io/kube-apiserver-client" ]; then
  echo "PASS 2: CSR jane signerName is kubernetes.io/kube-apiserver-client"
else
  echo "FAIL 2: CSR jane expected signerName kubernetes.io/kube-apiserver-client (got ${signer:-none})"
  fail=1
fi

# Check 3: usages include client auth
usages=$(kubectl get csr jane -o jsonpath='{.spec.usages}' 2>/dev/null)
case "$usages" in
  *"client auth"*)
    echo "PASS 3: CSR jane usages include client auth"
    ;;
  *)
    echo "FAIL 3: CSR jane expected usages to include client auth (got ${usages:-none})"
    fail=1
    ;;
esac

# Check 4: CSR jane is Approved
approved=$(kubectl get csr jane -o jsonpath='{.status.conditions[?(@.type=="Approved")].status}' 2>/dev/null)
if [ "$approved" = "True" ]; then
  echo "PASS 4: CSR jane is Approved"
else
  echo "FAIL 4: CSR jane not Approved (approved=${approved:-none})"
  fail=1
fi

# Check 5: CSR jane has a signed certificate in status.certificate
cert=$(kubectl get csr jane -o jsonpath='{.status.certificate}' 2>/dev/null)
if [ -n "$cert" ]; then
  echo "PASS 5: CSR jane is signed (status.certificate is set)"
else
  echo "FAIL 5: CSR jane has no status.certificate yet (not signed)"
  fail=1
fi

# Check 6: /tmp/jane.kubeconfig exists and is a valid kubeconfig
if kubectl --kubeconfig /tmp/jane.kubeconfig config view >/dev/null 2>&1; then
  echo "PASS 6: /tmp/jane.kubeconfig exists and is a valid kubeconfig"
else
  echo "FAIL 6: /tmp/jane.kubeconfig missing or not a valid kubeconfig"
  fail=1
fi

# Check 7: the kubeconfig authenticates as user jane (cert works)
who=$(kubectl --kubeconfig /tmp/jane.kubeconfig auth whoami -o jsonpath='{.status.userInfo.username}' 2>/dev/null)
if [ "$who" = "jane" ]; then
  echo "PASS 7: jane's kubeconfig authenticates as jane"
else
  echo "FAIL 7: expected authenticated user jane (got ${who:-none})"
  fail=1
fi

# Check 8: jane is authenticated but cannot get pods (forbidden)
can=$(kubectl --kubeconfig /tmp/jane.kubeconfig auth can-i get pods 2>/dev/null)
if [ "$can" = "no" ]; then
  echo "PASS 8: jane cannot get pods - authenticated but forbidden"
else
  echo "FAIL 8: expected 'no' from auth can-i get pods (got ${can:-error})"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - CSR jane Approved and signed, jane's kubeconfig authenticates without permissions"
exit 0
