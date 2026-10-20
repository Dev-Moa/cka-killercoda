# Jobs & CronJobs

You are logged in as `root` on **controlplane** of a two-node kubeadm
cluster (controlplane + node01). The cluster is ready and kubectl is
ready; `node01` is reachable with `ssh node01` if you ever need it.

A Job runs pods to completion — here it finishes 3 times. A CronJob
creates Jobs on a schedule, like cron in Linux. You will create both in
the `default` namespace and trigger the CronJob once by hand.
