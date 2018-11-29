echo "Removing service account"
az ad sp delete --id http://${RESOURCE_GROUP}_access
echo "Deleting all assets in resource group ${RESOURCE_GROUP}"
az group delete --name ${RESOURCE_GROUP} -y --verbose