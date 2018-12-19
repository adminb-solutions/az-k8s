#!/bin/bash

export LINUX_KEY_DATA=`cat /root/.azure/id_rsa.pub`
export AZ_SECRET=`jq .password -r /root/.azure/k8s.${RESOURCE_GROUP}.account.json`
export AZ_TENANT=`jq .tenant -r /root/.azure/k8s.${RESOURCE_GROUP}.account.json`
export AZ_CLIENT_ID=`jq .appId -r /root/.azure/k8s.${RESOURCE_GROUP}.account.json`

# Create a template for the cluster
envsubst < templates/template.json > hybrid-cluster.json


if [ -e "/output/${DNS_PREFIX}/apimodel.json" ]; then
    echo "Using supplied templates in /output/${DNS_PREFIX}"
    acs-engine generate --api-model /output/${DNS_PREFIX}/apimodel.json -o /output/${DNS_PREFIX}
else
    echo "Generated acs-engine template hybrid-cluster.json"
    acs-engine generate hybrid-cluster.json -o /output/${DNS_PREFIX} || exit 1
fi

echo "Creating resources in Azure"
az group deployment create --verbose --name ${DNS_PREFIX} --resource-group ${RESOURCE_GROUP} --template-file /output/${DNS_PREFIX}/azuredeploy.json --parameters /output/${DNS_PREFIX}/azuredeploy.parameters.json

echo 'export KUBECONFIG="/output/${DNS_PREFIX}/kubeconfig/kubeconfig.${LOCATION}.json"' >> /etc/environment
source /etc/environment

echo "kubectl configured using $KUBECONFIG file"
kubectl version
