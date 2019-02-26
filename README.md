# Hybrid Kubernetes cluster on Azure

Azure provides the [Azure Kubernetes Service (AKS)](https://azure.microsoft.com/en-us/services/kubernetes-service/) to run Kubernetes clusters. It works well as long as you are happy to use only Linux nodes. If you want to use Windows nodes, or a mixture of the two you are out of luck.

The purpose of this Docker image is to leverage [AKS-engine (formerly ACS-engine)](https://github.com/Azure/aks-engine) to create a hybrid environment of Windows and Linux nodes.

## Requirements

You will require an **account in Azure**, I won't cover that here since there is already [plenty of information](https://azure.microsoft.com/en-us/get-started/) available.

You will also require an **Azure subscription**.

## Usage

In the process of creating the cluster, the container creates various keys and config files. These are persisted in a volume in the path `/output`. You may want to mount that to a local folder in your machine. This will make it very easy to then extract the configuration file to connect to the cluster (or use the ssh keys to remote to the node machines).

```bash
docker run -v <some-local-path>:/output adminb/az-k8s
```

The container will first ask you to login to Azure and it will then create the right service accounts to create and run the cluster. After the container runs for 10/15 minutes, you should have a fully working kubernetes cluster.

You can then connect to it with `kubectl`, the Kubernetes CLI. You can use the one provided in this image:

```bash
docker run -ti -v <some-local-path>:/output adminb/az-k8s bash
export KUBECONFIG=/output/$DNS_PREFIX/kubeconfig/kubeconfig.$LOCATION.json
kubectl version
```

Or one in bare-metal in your machine:

```bash
export KUBECONFIG=<some-local-path>/kubeconfig/kubeconfig.ukwest.json
kubectl version
```

or in Windows

```powershell
$env:KUBECONFIG='<some-local-path>/kubeconfig/kubeconfig.ukwest.json'
kubectl version
```

It is safe to just run the image without parameters, however there are various things you might want to tweak. You can use the following environment variables:

| Variable               | Default value       | Notes                                                                                                   |
|------------------------|---------------------|---------------------------------------------------------------------------------------------------------|
| DNS_PREFIX             | hybrid-cluster-1    |                                                                                                         |
| MASTER_SIZE            | Standard_B1ms       | Size of machine to use for the master node                                                              |
| LINUX_WORKER_SIZE      | Standard_B2ms       | Size of machine to use the Linux nodes                                                                  |
| LINUX_WORKER_COUNT     | 1                   | Number of nodes running Linux                                                                           |
| WINDOWS_WORKER_SIZE    | Standard_B2ms       | Size of machine to use for Windows nodes                                                                |
| WINDOWS_WORKER_COUNT   | 1                   | Number of nodes running Windows                                                                         |
| WINDOWS_ADMIN_USER     | azureuser           | Windows admin user                                                                                      |
| WINDOWS_ADMIN_PASSWORD | buf(343)!#          | Windows admin password                                                                                  |
| LINUX_ADMIN_USER       | azureuser           | User for the Linux nodes                                                                                |
| LINUX_KEY_DATA         |                     | SSH key to use to be able to remote to Linux nodes (if undefined a new random key is generated)         |
| LOCATION               | ukwest              | Azure Location for the resources                                                                        |
| RESOURCE_GROUP         | hybrid-cluster-1    | Resource group where to create all the required elements (VMs, switches)                                |
| VERSION                | 1.12                | Version of K8s to use                                                                                   |
| AUTOSCALE              | false               | Enable autoscaling of nodes                                                                             |
| AUTOSCALE_MAX          | 5                   | Maximum number of nodes if autoscale is enabled                                                         |
| AUTOSCALE_MIN          | 1                   | Minimum number for nodes if autoscale is enabled                                                        |
| NETWORK_RESOURCE_GROUP |                     | Resource grouop where DNS network data is stored (if blank defaults to RESOURCE_GROUP)                  |
| USER_EMAIL             | john@doe.com        |                                                                                                         |

If you want to avoid the hassle of loggin in to azure every time you run the image, you can persist the login credentials in a volume:

```bash
docker volume create azure
docker run -v azure:/root/.azure -v <some-local-path>:/output adminb/az-k8s
```

### Extra features

Your cluster will also have an [nginx ingress controller](https://github.com/kubernetes/ingress-nginx) installed which you can use to create [ingress routes](https://kubernetes.io/docs/concepts/services-networking/ingress/).

When the container finishes setting up your cluster it will display the public IP of your ingress. 
The cluster will also have [Cert Manager](https://docs.cert-manager.io/en/latest/) installed.

If you manage your DNS in Azure, this image will perform further configuration for you:

- It will bind a wildcard route to the public IP of the ingress controller
- It will create Cert Issuers configured for the [DNS protocol](https://docs.cert-manager.io/en/latest/tutorials/acme/dns-validation.html), which can create SSL certs for your cluster (including wildcard certificates).

To get the benefit of these features you simply need to create a [DNS zone](https://docs.microsoft.com/en-us/azure/dns/dns-zones-records) in Azure. It can exist in the same resource group where you are installing the cluster, or even better you can have it in a separate resource group you bind with the environment variable `NETWORK_RESOURCE_GROUP`.

### Removing the cluster

You can run ```docker run adminb/az-k8s scripts/cleanup.sh``` to remove the entire cluster and service account. Make sure to pass the same environment variables you used to overwrite any default values.