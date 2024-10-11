# From there you can create a federated credential
az identity create --name ${USER_IDENTITY_NAME} --resource-group ${RESOURCE_GROUP}
az identity federated-credential create \
  --name "kubernetes-federated-credential" \
  --identity-name "${USER_IDENTITY_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --issuer "https://oidcdiscovery-northamerica-endpoint-gbcge4adgqebgxev.z01.azurefd.net/66efb79f-fc7a-4ec4-ba95-509ffcfb0918/" \
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