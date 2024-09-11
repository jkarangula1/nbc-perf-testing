#!/bin/bash

set -eux

source .env

# Create a storage account v2 with heirarchical namespace enabled
# Note we don't deny via default-action yet because we need to create a container first
az storage account create --name $STORAGE_ACCOUNT_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $RESOURCE_LOCATION \
    --sku Standard_LRS \
    --hns true \
    --allow-shared-key-access false \
    --allow-blob-public-access false \
    --default-action allow

# Create a container in the storage account
az storage container create --name $STORAGE_CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --auth-mode login

# Block access once we've created the container
az storage account update --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP --default-action deny

# Now we need to add the AKS cluster to the storage account's allow list

# Get the resource group for the AKS cluster
export AKS_RESOURCE_RG=$(az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query nodeResourceGroup -o tsv)

# Get the virtual network name
export AKS_VIRTUAL_NETWORK_NAME=$(az resource list --resource-group $AKS_RESOURCE_RG --resource-type "Microsoft.Network/virtualNetworks" --query "[].{Name:name}" -o tsv)

# List the subnets in the virtual network
export AKS_SUBNET_NAME=$(az network vnet subnet list --resource-group $AKS_RESOURCE_RG --vnet-name $AKS_VIRTUAL_NETWORK_NAME --query "[].name" -o tsv)

# Show the subnet ID
export AKS_SUBNET_ID=$(az network vnet subnet show --resource-group $AKS_RESOURCE_RG --vnet-name $AKS_VIRTUAL_NETWORK_NAME --name $AKS_SUBNET_NAME --query id -o tsv)

# Create a service endpoint for storage account
az network vnet subnet update \
    --name $AKS_SUBNET_NAME \
    --vnet-name $AKS_VIRTUAL_NETWORK_NAME \
    --resource-group $AKS_RESOURCE_RG \
    --service-endpoints "Microsoft.Storage"

# Add virtual network to allow list for storage
az storage account network-rule add \
    --account-name $STORAGE_ACCOUNT_NAME \
    --resource-group $RESOURCE_GROUP \
    --subnet $AKS_SUBNET_ID

# Get the managed identity and add the Storage Blob Data Contributor role
export MANAGED_IDENTITY_CLIENT_ID=$(az identity show --name $USER_IDENTITY_NAME --resource-group $RESOURCE_GROUP --query principalId -o tsv)
az role assignment create --assignee-object-id $MANAGED_IDENTITY_CLIENT_ID --assignee-principal-type ServicePrincipal --role "Storage Blob Data Contributor" --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME
