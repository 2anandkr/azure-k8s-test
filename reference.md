# Terraform setup on AKS

```sh
# https://docs.microsoft.com/en-us/azure/developer/terraform/get-started-cloud-shell#authenticate-via-azure-service-principal

# =============================
# FROM the azure cloud shell
# =============================

# 1. get the subscription id for the user
az account show
# SUBSCRIPTION_ID=2dc97483-8326-4ca5-86ac-5fffed6bb16a

# 2. create service principal with contributor role (The Contributor role (the default) has full permissions to read and write to an Azure account.)
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/$SUBSCRIPTION_ID"
# ==========================================
# FROM the azure cloud shell or local shell
# ==========================================

# https://docs.microsoft.com/en-us/cli/azure/

# 3. Log in using an Azure service principal:
az login --service-principal -u <service_principal_name> -p "<service_principal_password>" --tenant "<service_principal_tenant>"
az login --service-principal -u http://azure-cli-2021-04-20-14-27-11 -p "j~kCs4gpGQUhPA~8YUJ_pVAjUY96HII1kX" --tenant "936b1714-3a18-4c25-a00a-ad146eea1cd0"


# 3. Create and configure a storage backend

RESOURCE_GROUP_NAME=book-keeping
STORAGE_ACCOUNT_NAME=tfstateindex01
CONTAINER_NAME=tfstate
LOCATION=uaenorth
KEY_VAULT=index-devops
KEY_VAULT_SECRET_NAME=terraform-backend-key-poc

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)

# Create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY

echo "storage_account_name: $STORAGE_ACCOUNT_NAME"
echo "container_name: $CONTAINER_NAME"
echo "access_key: $ACCOUNT_KEY"

# create a key vault to store storage account key
az keyvault create --name $KEY_VAULT --resource-group $RESOURCE_GROUP_NAME --location $LOCATION
# Add a secret for storage account key to Key Vault
az keyvault secret set --vault-name $KEY_VAULT --name $KEY_VAULT_SECRET_NAME --value $ACCOUNT_KEY
# Create an environment variable named ARM_ACCESS_KEY with the value of the Azure Storage access key.
export ARM_ACCESS_KEY=$(az keyvault secret show --vault-name $KEY_VAULT --name $KEY_VAULT_SECRET_NAME --query value -o tsv)


# 4. azure AD integration with AKS

# create a new Azure AD group for your cluster administrators (from cloud shell as service principal will not have permission)
az ad group create --display-name indexAKSAdminGroup --mail-nickname indexAKSAdminGroup
  "objectId": "d66d7163-d507-4edf-878c-a2d82ff8f532"

az aks get-credentials --resource-group index-poc --name index-poc-aks

# destroy specific
terraform destroy -target=RESOURCE_TYPE.NAME -target=RESOURCE_TYPE2.NAME
```