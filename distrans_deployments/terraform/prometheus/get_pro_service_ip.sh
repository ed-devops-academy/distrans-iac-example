#!/bin/bash

set -e

terraform output -raw kube_config > ./kube_config

# eval "$(jq -r '@sh "KUBE_CONFIG=\(.kube_config)"')"

# echo $KUBE_CONFIG > ./kube_config

lbIP=$(kubectl --kubeconfig=./kube_config get service prometheus-kube-prometheus-prometheus -n prometheus -o json | jq .status.loadBalancer.ingress[0].ip | tr -d '"')

while [ "$lbIP" == "null" ]
do 
    lbIP=$(kubectl --kubeconfig=./kube_config get service prometheus-kube-prometheus-prometheus -n prometheus -o json | jq .status.loadBalancer.ingress[0].ip | tr -d '"')
done

jq -n --arg ip $lbIP '{"ip": $ip}'