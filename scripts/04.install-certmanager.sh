# Provide a different network group for the DNS config, otherwise use the default
network_group=${1:-${NETWORK_RESOURCE_GROUP:-$RESOURCE_GROUP}}
email=${2:-${USER_EMAIL:-'john@doe.com'}}
zone_account_path=~/.azure/k8s.dns.$network_group.account.json
zone_info_path=~/.azure/k8s.dns.$network_group.info.json

export KUBECONFIG="${PWD}/_output/${DNS_PREFIX}/kubeconfig/kubeconfig.${LOCATION}.json"

# taint the windows node to avoid linux containers landing on it
# known issue with cert-manager
kubectl taint node -l beta.kubernetes.io/os=windows windows=true:NoSchedule 2> /dev/null

echo "Using DNS zone in resource group $network_group"

# install cert-manager
[ -z `helm list cert-manager -q` ] && helm install stable/cert-manager --namespace kube-system --name cert-manager --set nodeSelector."beta\.kubernetes\.io/os"="linux"

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
    zone_id=`jq -r .Id $zone_info_path`
    SUBSCRIPTION_ID=`az account show --query 'id' -o tsv`        
    az ad sp create-for-rbac --name http://${network_group}_${RESOURCE_GROUP}_access --scopes "$zone_id" > $zone_account_path
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