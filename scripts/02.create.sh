export LINUX_KEY_DATA=`cat ~/.ssh/id_rsa.pub`
export AZ_SECRET=`jq .password -r ~/.azure/k8s.account.json`
export AZ_TENANT=`jq .tenant -r ~/.azure/k8s.account.json`
export AZ_CLIENT_ID=`jq .appId -r ~/.azure/k8s.account.json`

# Create a template for the cluster
envsubst < templates/template.json > hybrid-cluster.json

echo "Generated acs-engine template hybrid-cluster.json"
acs-engine generate hybrid-cluster.json

echo "Creating resources in Azure"
az group deployment create --verbose --name ${DNS_PREFIX} --resource-group ${RESOURCE_GROUP} --template-file _output/${DNS_PREFIX}/azuredeploy.json --parameters _output/${DNS_PREFIX}/azuredeploy.parameters.json

export KUBECONFIG="${PWD}/_output/${DNS_PREFIX}/kubeconfig/kubeconfig.${LOCATION}.json"
echo "kubectl configured using $KUBECONFIG file"
kubectl version

[ -d /output ] && cp $KUBECONFIG /output
