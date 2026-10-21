# Helm Install, Upgrade, and Rollback

You are root on controlplane of a two-node kubeadm cluster; kubectl is
ready and node01 is reachable with `ssh node01` if you ever need it.
Helm is already installed on controlplane.

You will add the Bitnami chart repository, install NGINX as a Helm
release, upgrade its replica count, and roll the release back. All
work happens in the `exercise-13` namespace, which Helm creates for
you when you install with `--create-namespace`.
