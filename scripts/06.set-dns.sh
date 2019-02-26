#!/bin/bash

source /etc/environment

network_group=${1:-${NETWORK_RESOURCE_GROUP:-$RESOURCE_GROUP}}
host=${2:-'*'}
zone_info_path=/root/.azure/k8s.dns.$network_group.info.json

while ! ip=`kubectl get svc --namespace ingress -l 'component=controller' -o json | jq -r .items[0].status.loadBalancer.ingress[].ip 2> /dev/null`  ; do
    sleep 1s
    [ -z $msg ] && echo "Waiting for ip - you can also cancel doing Ctrl+C and run the script later" && msg='shown'
done

if [ -e $zone_info_path ]; then
    domain=`jq -r .name $zone_info_path`

    echo "Mapping $ip to ${host}.${domain}"
    az network dns record-set a add-record -g $network_group -z $domain -n "$host" -a $ip
else
    echo "The public IP of your cluster is $ip"
    echo "No DNS has been bound to the cluster, since there are no DNS zones in the resource group."
fi