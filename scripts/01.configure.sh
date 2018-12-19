#!/bin/bash

az account show &> /dev/null || az login

# check if we are logged in
az account show &> /dev/null ||
    ( echo "You need to login first, run 'az login' or supply log-in credentials for a RBAC service account" && exit 1)


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
if [ ! -e /root/.azure/k8s.${RESOURCE_GROUP}.account.json ]; then    
    SUBSCRIPTION_ID=`az account show --query 'id' -o tsv`
    ACCOUNT_ID=http://${RESOURCE_GROUP}_k8s
    az ad sp create-for-rbac --name $ACCOUNT_ID --scopes "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}" > /root/.azure/k8s.${RESOURCE_GROUP}.account.json
fi

# Create a key for the linux machines. You can then login to the master node doing ssh
if [ ! -e /root/.azure/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -N "" -f /root/.azure/id_rsa    
fi
mkdir -p /root/.ssh
cp /root/.azure/id_rsa* /root/.ssh
