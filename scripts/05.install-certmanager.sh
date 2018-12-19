#!/bin/bash

# Provide a different network group for the DNS config, otherwise use the default
network_group=${1:-${NETWORK_RESOURCE_GROUP:-$RESOURCE_GROUP}}
email=${2:-${USER_EMAIL:-'john@doe.com'}}
zone_account_path="/root/.azure/k8s.dns.$network_group.account.json"
zone_info_path="/root/.azure/k8s.dns.$network_group.info.json"

source /etc/environment


# taint the windows node to avoid linux containers landing on it
# known issue with cert-manager
kubectl taint node -l beta.kubernetes.io/os=windows windows=true:NoSchedule 2> /dev/null

echo "Using DNS zone in resource group $network_group"

# install or upgrade cert-manager
helm upgrade cert-manager --install --namespace kube-system --set nodeSelector."beta\.kubernetes\.io/os"="linux" stable/cert-manager

# create a service account to access the DNS az zone

if [ ! -e $zone_account_path ]; then
    dns_zone_count=`az network dns zone list -g $network_group --query='length([])' -o tsv`

    if [ $dns_zone_count -eq 0 ]; then
        echo "Cannot find any zones in $network_group"
        exit 1
    elif [ $dns_zone_count -gt 1 ]; then
        az network dns zone list -g $network_group --query='[].{Host:name}' -o table
        read "Choose a host: " hostname
        az network dns zone show -n $hostname -g $network_group --query='[].{Id:id,Name:name}' > $zone_info_path    
    else # there is only one network
        az network dns zone list -g $network_group --query='[0].{id:id,name:name}' > $zone_info_path
    fi
    zone_id=`jq -r .id $zone_info_path`
    rbac_name="http://${network_group}_${RESOURCE_GROUP}_k8s"
    az ad sp delete --id $rbac_name
    az ad sp create-for-rbac --name $rbac_name --scopes "$zone_id" > $zone_account_path
fi

# create secret with azure password

# create issuer

export AZ_CLIENT_ID=`jq -r .appId $zone_account_path`
export AZ_RESOURCE_GROUP=$network_group    
export AZ_SUBSCRIPTION_ID=`az account show --query 'id' -o tsv`
export AZ_TENANT_ID=`jq -r .tenant $zone_account_path`
export AZ_HOSTNAME=`jq -r .name $zone_info_path`
export EMAIL="$email"

password=`jq -r .password $zone_account_path`

while ! kubectl create secret generic azure-secret --from-literal="password=$password" 2> /dev/null; do 
    echo "recreating azure-secret"
    kubectl delete secret azure-secret
done

envsubst < templates/issuer.staging.yml | kubectl apply -f -