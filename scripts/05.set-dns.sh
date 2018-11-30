#!/bin/bash

network_group=${1:-${NETWORK_RESOURCE_GROUP:-$RESOURCE_GROUP}}
host=${2:-'*'}
zone_info_path=/root/.azure/k8s.dns.$network_group.info.json
domain=`jq -r .name $zone_info_path`

export KUBECONFIG="${PWD}/_output/${DNS_PREFIX}/kubeconfig/kubeconfig.${LOCATION}.json"


while ! ip=`kubectl get svc --namespace ingress -l 'component=controller' -o json | jq -r .items[0].status.loadBalancer.ingress[].ip 2> /dev/null`  ; do
    sleep 1s
    [ -z $msg ] && echo "Waiting for ip - you can also cancel doing Ctrl+C and run the script later" && msg='shown'
done

echo "Mapping $ip to ${host}.${domain}"
az network dns record-set a add-record -g $network_group -z $domain -n "$host" -a $ip
