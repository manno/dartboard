#!/bin/zsh

### etcd size
./default_config/ssh-to-upstream-server-0.sh du -sh /var/lib/rancher/rke2/server/db/

kubectl config use-context  upstream

#clusters=500
clusters=2000
agents=$clusters
bundles=50
cluster_ready="$clusters/$clusters" # 500/500
test_bd=$(( clusters * bundles ))   # 25000
total_bd=$(( agents + test_bd ))    # 25500
test_bd_ready="$test_bd/$test_bd"   # 25000/25000
#bundles_per_cluster=$(( 1 + bundles )) # 51

### Create
kubectl apply -f ./gitrepo-scale-50-bundles-single.yaml -n fleet-default
echo
echo -n "created gitrepo for 50 bundles: "
date

while (( $(kubectl get --no-headers --chunk-size=0 -n fleet-default bundle -l "fleet.cattle.io/repo-name=scale-50-single" 2> /dev/null | wc -l) != 50 )); do echo -n .; sleep 1; done
echo
echo -n "bundles exist: "
date

while (( $(kubectl get --no-headers --chunk-size=0 -A bundledeployments | wc -l) != "$total_bd" )); do echo -n .; sleep 10; done
echo
echo -n "bundledeployments exist: "
date

while (( $(kubectl get --no-headers --chunk-size=0 -n fleet-default bundle -l "fleet.cattle.io/repo-name=scale-50-single" | grep "$cluster_ready" | wc -l) != 50 )); do echo -n .; sleep 5; done
echo
echo -n "bundles ready: "
date

while ! kubectl get -n fleet-default gitrepo scale-50-single | grep -q "$test_bd_ready"; do echo -n .; sleep 5; done
echo
echo -n "gitrepo ready: "
date

while (( $(kubectl get --no-headers --chunk-size=0 -n fleet-default clusters | grep 51/51 | wc -l) != "$clusters" )); do echo -n .; sleep 5; done
echo
echo -n "clusters ready: "
date

### Delete
echo "=== delete"
kubectl delete -n fleet-default gitrepo scale-50-single
while (( $(kubectl get --chunk-size=0 -n fleet-default clusters | grep 1/1 | wc -l) != "$clusters" )); do echo -n .; sleep 5; done
echo
echo -n "clusters 1/1: "
date

while (( $( kubectl get secrets --no-headers -A --field-selector type=fleet.cattle.io/bundle-deployment/v1alpha1 | wc -l ) != 0 )); do echo -n .; sleep 5; done
echo
echo -n "secrets removed: "
date

### etcd size
./default_config/ssh-to-upstream-server-0.sh du -sh /var/lib/rancher/rke2/server/db/
