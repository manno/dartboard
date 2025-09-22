#!/bin/zsh

set -u

# do change in git
kubectl apply -f ./gitrepo-scale-50-bundles-single.yaml -n fleet-default
echo
echo -n "created gitrepo for 50 bundles: "
date
while ! kubectl get -n fleet-default gitrepo scale-50-single | grep -q 25000/25000; do echo -n .; sleep 5; done
echo
echo -n "gitrepo ready: "
date

printf "update git and tell me the new commit? "
read commit

#commit=${0:}

if [ -z "$commit" ]; then
  echo "failed to read commit: $commit"
  exit 1
fi

while (( $(kubectl get --no-headers --chunk-size=0 -n fleet-default bundle -l "fleet.cattle.io/commit=$commit" 2> /dev/null | wc -l) != 50 )); do echo -n .; sleep 1; done
echo
echo -n "bundles for commit $commit exist: "
date

while (( $(kubectl get --no-headers --chunk-size=0 -A bundledeployments -l "fleet.cattle.io/commit=$commit" | wc -l) != 25000 )); do echo -n .; sleep 10; done
echo
echo -n "bundledeployments exist: "
date

while (( $(kubectl get --no-headers --chunk-size=0 -n fleet-default bundle -l "fleet.cattle.io/commit=$commit" | grep 500/500 | wc -l) != 50 )); do echo -n .; sleep 5; done
echo
echo -n "bundles ready: "
date

while ! kubectl get -n fleet-default gitrepo scale-50-single | grep -q 25000/25000; do echo -n .; sleep 5; done
echo
echo -n "gitrepo ready again: "
date
