# Azure Infra Setup 

**`Required Tooling`: azure cli, terraform(0.15+), kubectl(1.18.8+), helm 3, istioctl(tested with 1.9.4), jq**

## 1. Login using your subscription account
```sh
az login
az account show
```

## 2. Configure a storage backend for storing remote terraform state and a Static IP for the cluster load balancer
```sh
RESOURCE_GROUP_NAME=book-keeping
STORAGE_ACCOUNT_NAME=tfstateindex001
CONTAINER_NAME=tfstate
LOCATION=uaenorth
# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION
# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob
# Get storage account key
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)
# Create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY

# Create the Static IP to be used by the cluster load balancer
az network public-ip create --resource-group $RESOURCE_GROUP_NAME --name indexAKSPublicIP --sku Standard --allocation-method static
# find it (if not noted from above command)
az network public-ip show --resource-group $RESOURCE_GROUP_NAME --name indexAKSPublicIP --query ipAddress --output tsv

```

## 3. Azure AD integration with AKS 
```sh
# create a new Azure AD group for your cluster administrators 
az ad group create --display-name indexAKSAdminGroup --mail-nickname indexAKSAdminGroup
# add the azure AD user to the group
az ad group member add --group indexAKSAdminGroup --member-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
# verify
az ad group member check --group indexAKSAdminGroup --member-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
az ad group member list --group indexAKSAdminGroup

# register the above group and current subscription tenant ID during kubernetes cluster creation in "terraform.tfvars"
# cluster_azure_ad_groups    = ["xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"]
# cluster_azure_ad_tenant_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

## 4. Create Azure Infra with terraform
```sh
# configure terraform.tfvars
# review the infra. plan
terraform plan
# create infra. based on the plan
terraform apply
# refresh remote state to get the public IPs for VMs
terraform refresh
```

## 5 Test your kubernetes cluster access
```sh
# get and store cluster credentials to your kube_config
az aks get-credentials --resource-group index-poc --name index-poc-aks
# test access. (would be prompted to login to your azure AD; if you are a member of the cluster AD group, the below command should work)
kubectl get nodes
```

## 6. Boot the cluster and the VMs

```sh
# The below command (bootstrap the cluster and linux VM):
# - installs Istio
# - sets up Istio gateway and services needed for VM integration
# - generate service account token to use for MTLS 
# - generate files to be used by VMs to configure their Istio Sidecar
# - on linux VMs, it syncs the integration files and sets up the Istio Sidecar. 
# - sets up the test cluster and Istio resources to test the integration
./boot.sh

# ingress setup (currently using this in boot script errs due to resources taking time; until resolved you can just exectute them manually)
kubectl create ns nginx
helm install nginx-ingress ingress-nginx/ingress-nginx -n nginx -f ./helm-charts/nginx-ingress.yaml
# setup cert-manager...
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml
# create certificate issuer...
kubectl apply -f $THIS_DIR/certificate-issuer/letsencrypt-prod.yaml
# test ingress with certs
kubectl apply -f ./apps/hello.yaml

#
# login to the Wiindows VM (via any RDP client using the Public IP);
# from powershell (as administrator) install IIS server (to test service connectivity from the cluster)
#
Install-WindowsFeature -name Web-Server -IncludeManagementTools

```

## 7. Delete Azure Resources
```sh
terraform destroy

```
