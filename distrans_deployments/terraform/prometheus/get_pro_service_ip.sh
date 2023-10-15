#!/bin/bash

lbIP=$(kubectl get service prometheus-kube-prometheus-prometheus -n prometheus -o json | jq .status.loadBalancer.ingress[0].ip | tr -d '"')

while [ "$lbIP" == "null" ]
do 
    lbIP=$(kubectl get service prometheus-kube-prometheus-prometheus -n prometheus -o json | jq .status.loadBalancer.ingress[0].ip | tr -d '"')
done

jq -n --arg ip $lbIP '{"ip": $ip}'