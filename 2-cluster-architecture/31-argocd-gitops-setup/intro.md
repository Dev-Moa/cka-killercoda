# Argo CD GitOps setup

You are root on controlplane of a two-node kubeadm cluster; kubectl is
ready and node01 is reachable with `ssh node01` if you ever need it.

Argo CD is a GitOps controller: it reads a Git repository and keeps the
cluster matching it. An `Application` is its custom resource: it names
the repo, the path inside it, and the namespace to deploy into.

In this exercise you install Argo CD into the `argocd` namespace from
its manifests, write one Application resource, apply it, and confirm
it reaches `Synced`. The reported exam version of this task installs
Argo CD with Helm instead (dumbITguy Q02); the Application part is the
same.
