#!/bin/bash
# Wait until the kubeadm nodes are Ready before the candidate starts.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes

# The exercise's own Setup block, run hidden (the candidate must not see
# the breaks). Node names do not appear in it, so it runs as written.
kubectl create ns shop
kubectl run webapp --image=nginx -l name=webapp -n shop
kubectl expose pod webapp --port=8080 --target-port=80 --name=web-service -n shop
kubectl patch svc web-service -n shop -p '{"spec":{"selector":{"name":"webap"}}}'      # break 1: selector typo
kubectl run db --image=mysql -l name=db -n shop                                         # break 2: no MYSQL_ROOT_PASSWORD, crashes
kubectl run cache --image=redis:does-not-exist -n shop                                  # break 3: bad image tag

# Record the Service UID: task 1 says fix it WITHOUT deleting the Service.
mkdir -p /tmp/exam
kubectl get svc web-service -n shop -o jsonpath='{.metadata.uid}' > /tmp/exam/web-service-uid.txt
exit 0
