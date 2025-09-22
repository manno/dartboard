#!/bin/zsh

bastion=$(sed -n '/root@/ s/\\//p' default_config/ssh-to-bastion.sh | tr -d ' ' )
scp -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ~/.ssh/fleetscale ./default_config/upstream-direct.yaml "$bastion":upstream.yaml

./default_config/ssh-to-bastion.sh "
zypper in -y kubernetes-client helm;
wget https://github.com/rancher/fleet/releases/download/v0.13.1/fleet-benchmark-linux-arm64;

export KUBECONFIG=/root/upstream.yaml;
kubectl config use-context upstream;
kubectl label clusters.fleet.cattle.io --all -n fleet-default fleet.cattle.io/benchmark=true;

chmod +x ./fleet-benchmark-linux-arm64;
./fleet-benchmark-linux-arm64 run -n fleet-default;

"

scp -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ~/.ssh/fleetscale \
    "$bastion":b-\* .
