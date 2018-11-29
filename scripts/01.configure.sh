# login
az account show &> /dev/null || az login

# there are several subscriptions, select the right one
if [ `az account list --query='length([])'` -gt 1 ]; then
    az account list --query='[].{Name: name, ID: id}' -o table
    read -p "Type the subscription name to use: " subscription
    az account set --subscription $subscription
fi

az configure --defaults location=$LOCATION

# Create resource group if it does not exist
if ! az group show -n $RESOURCE_GROUP &> /dev/null; then
    echo "Creating resource group $RESOURCE_GROUP in $LOCATION"
    az group create -n $RESOURCE_GROUP > /dev/null
    az configure --defaults group=$RESOURCE_GROUP
fi

# Create a service account for the cluster - only has access to the resource group
# The cluster needs this account to be able to create public IPs for Load balancers, or storage for volumes
if [ ! -e ~/.azure/k8s.account.json ]; then    
    SUBSCRIPTION_ID=`az account show --query 'id' -o tsv`
    az ad sp create-for-rbac --name http://${RESOURCE_GROUP}_access --scopes "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}" > ~/.azure/k8s.account.json    
fi

# Create a key for the linux machines. You can then login to the master node doing ssh
if [ ! -e ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
fi
