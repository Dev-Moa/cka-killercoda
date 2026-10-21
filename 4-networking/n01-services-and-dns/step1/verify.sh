#!/bin/bash
# N01: namespace apps, pod web (app=web) Running, Service web-service
# (ClusterIP :80, endpoint = the pod), DNS: short name resolves from
# apps and web-service.apps resolves from default, Service web-nodeport
# (NodePort 80:30080) and the node answers on 30080.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

# Check 1: pod web in apps is Running with label app=web
phase=$(kubectl get pod web -n apps -o jsonpath='{.status.phase}' 2>/dev/null)
lbl=$(kubectl get pod web -n apps -o jsonpath='{.metadata.labels.app}' 2>/dev/null)
if [ "$phase" = "Running" ] && [ "$lbl" = "web" ]; then
  echo "PASS 1: pod web in apps is Running with label app=web"
else
  echo "FAIL 1: pod web in apps expected Running with label app=web (got phase=${phase:-not found} app=${lbl:-none})"
  fail=1
fi

# Check 2: service web-service in apps is ClusterIP on port 80
type=$(kubectl get svc web-service -n apps -o jsonpath='{.spec.type}' 2>/dev/null)
ports=$(kubectl get svc web-service -n apps -o jsonpath='{.spec.ports[*].port}' 2>/dev/null)
if [ "$type" = "ClusterIP" ] && echo " $ports " | grep -q ' 80 '; then
  echo "PASS 2: service web-service in apps is ClusterIP on port 80"
else
  echo "FAIL 2: service web-service in apps expected ClusterIP port 80 (got type=${type:-none} ports=${ports:-none})"
  fail=1
fi

# Check 3: web-service has the pod's IP as its endpoint
podip=$(kubectl get pod web -n apps -o jsonpath='{.status.podIP}' 2>/dev/null)
eps=$(kubectl get endpointslices -n apps -l kubernetes.io/service-name=web-service -o jsonpath='{.items[*].endpoints[*].addresses[*]}' 2>/dev/null)
if [ -n "$podip" ] && echo " $eps " | grep -q " $podip "; then
  echo "PASS 3: web-service endpoint is the pod IP $podip"
else
  echo "FAIL 3: web-service endpoints (${eps:-none}) do not include pod web's IP (${podip:-none}) - check the selector matches app=web"
  fail=1
fi

# dns_lookup <namespace> <name>: nslookup from a throw-away busybox pod
dns_lookup() {
  kubectl run "dnscheck-$RANDOM" -n "$1" --image=busybox:1.36 --restart=Never --rm -i --quiet \
    --pod-running-timeout=90s -- nslookup "$2" 2>/dev/null
}

# Check 4: from a pod in apps the short name web-service resolves
out=""
for _ in 1 2 3; do
  out=$(dns_lookup apps web-service)
  echo "$out" | grep -qi 'web-service' && echo "$out" | grep -qE 'Address.*[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' && break
  sleep 3
done
if echo "$out" | grep -qi 'web-service' && echo "$out" | grep -qE 'Address.*[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'; then
  echo "PASS 4: short name web-service resolves from a pod in apps"
else
  echo "FAIL 4: web-service does not resolve from a pod in apps (nslookup said: $(echo "$out" | tr '\n' ' ' | cut -c1-160))"
  fail=1
fi

# Check 5: from a pod in default the namespaced name web-service.apps resolves
out=""
for _ in 1 2 3; do
  out=$(dns_lookup default web-service.apps)
  echo "$out" | grep -qi 'web-service.apps' && echo "$out" | grep -qE 'Address.*[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' && break
  sleep 3
done
if echo "$out" | grep -qi 'web-service.apps' && echo "$out" | grep -qE 'Address.*[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'; then
  echo "PASS 5: web-service.apps resolves from a pod in default"
else
  echo "FAIL 5: web-service.apps does not resolve from a pod in default (nslookup said: $(echo "$out" | tr '\n' ' ' | cut -c1-160))"
  fail=1
fi

# Check 6: service web-nodeport in apps is NodePort, port 80, nodePort 30080, selects app=web
type=$(kubectl get svc web-nodeport -n apps -o jsonpath='{.spec.type}' 2>/dev/null)
np=$(kubectl get svc web-nodeport -n apps -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}' 2>/dev/null)
sel=$(kubectl get svc web-nodeport -n apps -o jsonpath='{.spec.selector.app}' 2>/dev/null)
if [ "$type" = "NodePort" ] && [ "$np" = "30080" ] && [ "$sel" = "web" ]; then
  echo "PASS 6: service web-nodeport is NodePort 80:30080 selecting app=web"
else
  echo "FAIL 6: service web-nodeport expected NodePort, port 80 with nodePort 30080, selector app=web (got type=${type:-none} nodePort=${np:-none} selector.app=${sel:-none})"
  fail=1
fi

# Check 7: the node answers on 30080 (nginx welcome page), retry while kube-proxy programs the port
node_ip=$(kubectl get node controlplane -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null)
code=""
for _ in 1 2 3 4; do
  code=$(curl -s -o /dev/null -m 5 -w '%{http_code}' "http://${node_ip}:30080/" 2>/dev/null)
  [ "$code" = "200" ] && break
  sleep 3
done
if [ "$code" = "200" ]; then
  echo "PASS 7: http://${node_ip}:30080 answers 200 from the node"
else
  echo "FAIL 7: http://${node_ip}:30080 did not answer 200 (got ${code:-no response})"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - web-service resolves by short and namespaced name, web-nodeport serves on 30080"
exit 0
