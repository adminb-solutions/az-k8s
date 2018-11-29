export KUBECONFIG="${PWD}/_output/${DNS_PREFIX}/kubeconfig/kubeconfig.${LOCATION}.json"

helm init --upgrade --node-selectors "beta.kubernetes.io/os"="linux"

while [ ! helm version &> /dev/null ]; do
    sleep 1s
done

helm install stable/nginx-ingress --namespace ingress --name ingress  --set rbac.create="true",controler.extraArgs="enable-ssl-passthrough",controller.nodeSelector."beta\.kubernetes\.io/os"="linux",defaultBackend.nodeSelector."beta\.kubernetes\.io/os"="linux"
