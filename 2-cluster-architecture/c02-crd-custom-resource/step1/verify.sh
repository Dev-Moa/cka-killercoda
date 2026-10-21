#!/bin/bash
# C02 step 1: the CronTab CRD exists with the docs-example fields, and
# the CronTab object my-new-cron-object is in default with the right spec.
# Evidence-only output, also written to /tmp/check-report.txt.
: > /tmp/check-report.txt
exec > >(tee -a /tmp/check-report.txt) 2>&1

fail=0

CRD=crontabs.stable.example.com

# Check 1: the CRD exists
name=$(kubectl get crd "$CRD" -o jsonpath='{.metadata.name}' 2>/dev/null)
if [ "$name" = "$CRD" ]; then
  echo "PASS 1: CRD $CRD exists"
else
  echo "FAIL 1: CRD $CRD not found (got name=${name:-none})"
  fail=1
fi

# Check 2: spec.group is stable.example.com
group=$(kubectl get crd "$CRD" -o jsonpath='{.spec.group}' 2>/dev/null)
if [ "$group" = "stable.example.com" ]; then
  echo "PASS 2: CRD group is stable.example.com"
else
  echo "FAIL 2: CRD group expected stable.example.com (got ${group:-none})"
  fail=1
fi

# Check 3: spec.scope is Namespaced
scope=$(kubectl get crd "$CRD" -o jsonpath='{.spec.scope}' 2>/dev/null)
if [ "$scope" = "Namespaced" ]; then
  echo "PASS 3: CRD scope is Namespaced"
else
  echo "FAIL 3: CRD scope expected Namespaced (got ${scope:-none})"
  fail=1
fi

# Check 4: names.plural is crontabs
plural=$(kubectl get crd "$CRD" -o jsonpath='{.spec.names.plural}' 2>/dev/null)
if [ "$plural" = "crontabs" ]; then
  echo "PASS 4: CRD names.plural is crontabs"
else
  echo "FAIL 4: CRD names.plural expected crontabs (got ${plural:-none})"
  fail=1
fi

# Check 5: names.kind is CronTab
kind=$(kubectl get crd "$CRD" -o jsonpath='{.spec.names.kind}' 2>/dev/null)
if [ "$kind" = "CronTab" ]; then
  echo "PASS 5: CRD names.kind is CronTab"
else
  echo "FAIL 5: CRD names.kind expected CronTab (got ${kind:-none})"
  fail=1
fi

# Check 6: shortNames contains ct
short=$(kubectl get crd "$CRD" -o jsonpath='{.spec.names.shortNames}' 2>/dev/null)
case "$short" in
  *'"ct"'*)
    echo "PASS 6: CRD shortNames contain ct"
    ;;
  *)
    echo "FAIL 6: CRD shortNames expected to contain ct (got ${short:-none})"
    fail=1
    ;;
esac

# Check 7: version v1 exists and is served
vname=$(kubectl get crd "$CRD" -o jsonpath='{.spec.versions[0].name}' 2>/dev/null)
served=$(kubectl get crd "$CRD" -o jsonpath='{.spec.versions[0].served}' 2>/dev/null)
if [ "$vname" = "v1" ] && [ "$served" = "true" ]; then
  echo "PASS 7: CRD version v1 is served"
else
  echo "FAIL 7: CRD expected version v1 served (got name=${vname:-none} served=${served:-none})"
  fail=1
fi

# Check 8: schema defines spec.cronSpec as a string
crontype=$(kubectl get crd "$CRD" -o jsonpath='{.spec.versions[0].schema.openAPIV3Schema.properties.spec.properties.cronSpec.type}' 2>/dev/null)
if [ "$crontype" = "string" ]; then
  echo "PASS 8: CRD schema has spec.cronSpec (string)"
else
  echo "FAIL 8: CRD schema expected spec.cronSpec string (got ${crontype:-none})"
  fail=1
fi

# Check 9: schema defines spec.image as a string
imgtype=$(kubectl get crd "$CRD" -o jsonpath='{.spec.versions[0].schema.openAPIV3Schema.properties.spec.properties.image.type}' 2>/dev/null)
if [ "$imgtype" = "string" ]; then
  echo "PASS 9: CRD schema has spec.image (string)"
else
  echo "FAIL 9: CRD schema expected spec.image string (got ${imgtype:-none})"
  fail=1
fi

# Check 10: the CronTab object exists in default
obj=$(kubectl get "$CRD" my-new-cron-object -n default -o jsonpath='{.metadata.name}' 2>/dev/null)
if [ "$obj" = "my-new-cron-object" ]; then
  echo "PASS 10: CronTab my-new-cron-object exists in default"
else
  echo "FAIL 10: CronTab my-new-cron-object not found in default (got ${obj:-none})"
  fail=1
fi

# Check 11: spec.cronSpec is the expected value
cron=$(kubectl get "$CRD" my-new-cron-object -n default -o jsonpath='{.spec.cronSpec}' 2>/dev/null)
if [ "$cron" = "* * * * */5" ]; then
  echo "PASS 11: cronSpec is \"* * * * */5\""
else
  echo "FAIL 11: cronSpec expected \"* * * * */5\" (got ${cron:-none})"
  fail=1
fi

# Check 12: spec.image is the expected value
img=$(kubectl get "$CRD" my-new-cron-object -n default -o jsonpath='{.spec.image}' 2>/dev/null)
if [ "$img" = "my-awesome-cron-image" ]; then
  echo "PASS 12: image is my-awesome-cron-image"
else
  echo "FAIL 12: image expected my-awesome-cron-image (got ${img:-none})"
  fail=1
fi

if [ "$fail" = "1" ]; then
  echo "RESULT: FAIL - see the FAIL lines above"
  exit 1
fi
echo "RESULT: PASS - CronTab CRD and my-new-cron-object are in place"
exit 0
