#!/bin/bash

set -e

source ./.env

export AKS_RESOURCE_RG=$(az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query nodeResourceGroup -o tsv)

# Get the virtual network name
export AKS_VIRTUAL_NETWORK_NAME=$(az resource list --resource-group $AKS_RESOURCE_RG --resource-type "Microsoft.Network/virtualNetworks" --query "[].{Name:name}" -o tsv)

# List the subnets in the virtual network
export AKS_SUBNET_NAME=$(az network vnet subnet list --resource-group $AKS_RESOURCE_RG --vnet-name $AKS_VIRTUAL_NETWORK_NAME --query "[].name" -o tsv)

# Show the subnet ID
export AKS_SUBNET_ID=$(az network vnet subnet show --resource-group $AKS_RESOURCE_RG --vnet-name $AKS_VIRTUAL_NETWORK_NAME --name $AKS_SUBNET_NAME --query id -o tsv)

# Also needs a network security group
# az network public-ip create \
#   --resource-group $RESOURCE_GROUP \
#   --name $VM_PUBLIC_IP_NAME \
#   --allocation-method Static

# az network nic create \
#   --resource-group $RESOURCE_GROUP \
#   --name $VM_NIC_NAME \
#   --subnet $AKS_SUBNET_ID \
#   --public-ip-address $VM_PUBLIC_IP_NAME

# Create a VM and put it in the virtual network
rm ~/.ssh/id_rsa ~/.ssh/id_rsa.pub
az vm create \
  --resource-group $RESOURCE_GROUP \
  --name $VM_NAME \
  --image Ubuntu2204 \
  --admin-username azureuser \
  --public-ip-address \
  --generate-ssh-keys

  # --public-ip-address $VM_PUBLIC_IP_NAME \

chmod 400 ~/.ssh/id_rsa
chmod 400 ~/.ssh/id_rsa.pub


