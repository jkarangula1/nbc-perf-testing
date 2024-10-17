#!/bin/bash

set -e

source .env

# Check if the resource group exists
if ! $(az group exists --name $RESOURCE_GROUP); then
  # Create the resource group if it doesn't exist
  az group create --name $RESOURCE_GROUP --location $RESOURCE_LOCATION
else
  echo "Resource group $RESOURCE_GROUP already exists."
fi

# Create the AKS cluster
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --node-count 5 \
  --enable-managed-identity \
  --node-vm-size Standard_D4ds_v5 \
  --network-plugin azure \
  --network-policy calico \
  --generate-ssh-keys \
  --enable-oidc-issuer

az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME

# To show the OIDC repo name
OIDC_REPO="$(az aks show --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --query "oidcIssuerProfile.issuerUrl" -o tsv)"

# From there you can create a federated credential
az identity create --name ${USER_IDENTITY_NAME} --resource-group ${RESOURCE_GROUP}
az identity federated-credential create \
  --name "kubernetes-federated-credential" \
  --identity-name "${USER_IDENTITY_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --issuer "${OIDC_REPO}" \
  --subject "system:serviceaccount:${SERVICE_ACCOUNT_NAMESPACE}:${SERVICE_ACCOUNT_NAME}"

# Deploy the authentication pods which use the federated credential to authenticate the NBC dataflow
helm repo add azure-workload-identity https://azure.github.io/azure-workload-identity/charts
helm repo update
helm install workload-identity-webhook azure-workload-identity/workload-identity-webhook \
   --namespace azure-workload-identity-system \
   --create-namespace \
   --set azureTenantID="${TENANT_ID}"

# For deployments, you will need the tenant ID and client ID. The tenant ID was set above and the client
# ID can be fetched as follows
az identity show --name ${USER_IDENTITY_NAME} --resource-group ${RESOURCE_GROUP} | grep clientId

# Assign the managed identity to the resource group
export MANAGED_IDENTITY_CLIENT_ID=$(az identity show --name $USER_IDENTITY_NAME --resource-group $RESOURCE_GROUP --query principalId -o tsv)

az role assignment create --assignee-object-id $MANAGED_IDENTITY_CLIENT_ID --assignee-principal-type ServicePrincipal --role "Contributor" --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP

if [ "$1" == "connectk8s" ]; then
  echo "Connecting the AKS cluster to Azure Arc"
  # Connect the AKS cluster to Azure Arc
  az connectedk8s connect --name $ARC_NAME --resource-group $RESOURCE_GROUP --location $RESOURCE_LOCATION
fi
