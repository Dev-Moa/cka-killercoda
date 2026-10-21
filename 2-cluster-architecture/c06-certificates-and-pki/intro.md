# Certificates and PKI

You are root on controlplane of a two-node kubeadm cluster; kubectl is
ready and node01 is reachable with `ssh node01` if you ever need it.

This exercise drills the exam's certificate flow: view the API server's
kubelet client certificate, then take a new user `jane` from a key and
CSR to a signed certificate and a working kubeconfig. CSR objects are
cluster-scoped, so this exercise uses no namespace.
