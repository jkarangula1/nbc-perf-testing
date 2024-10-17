#!/bin/bash

source .env

# Warning this one is finicky because some of the commands are in preview.

az config set extension.use_dynamic_install=yes_without_prompt

# Deploy an Event Grid Namespace
# Deploy an Event Grid Namespace
az eventgrid namespace create \
  --name $EVENTGRID_NAMESPACE \
  --resource-group $RESOURCE_GROUP \
  --location $RESOURCE_LOCATION \
  --topic-spaces-configuration "{state:Enabled,client-authentication:{alternative-authentication-name-sources:['ClientCertificateSubject']}}"

az eventgrid namespace topic create --name $EVENTGRID_TOPIC_NAME --namespace-name $EVENTGRID_NAMESPACE --resource-group $RESOURCE_GROUP

# LEAVING THIS HERE FOR REFERENCE

# Create the client certificate
# mkdir -p cert/$EVENTGRID_FLOW_CLIENT_ID
# pushd cert/$EVENTGRID_FLOW_CLIENT_ID
# openssl ecparam -out ca_key.pem -name prime256v1 -genkey
# openssl req -new -days 3650 -nodes -x509 -key ca_key.pem -out ca_cert.pem -subj "/CN=Perf Tests CA" -extensions v3_ca
# echo -e "Created CA cert"

# openssl ecparam -out device_ec_key.pem -name prime256v1 -genkey
# openssl req -new -key device_ec_key.pem -out device_ec_cert.csr -subj "/CN=$EVENTGRID_FLOW_CLIENT_ID"
# openssl x509 -req -in device_ec_cert.csr -CA ca_cert.pem -CAkey ca_key.pem -CAcreateserial -out device_ec_cert.pem -days 3650 -sha256
# echo -e "Created device cert"
# popd

# Removing the last newline from the CA cert since Event Grid doesn't like it
# sed -z '$ s/\n$//' ./cert/$EVENTGRID_FLOW_CLIENT_ID/ca_cert.pem > ./cert/$EVENTGRID_FLOW_CLIENT_ID/ca_cert_upload.pem

# az eventgrid namespace ca-certificate create \
#   --resource-group $RESOURCE_GROUP \
#   --namespace-name $EVENTGRID_NAMESPACE \
#   --ca-certificate-name perf-ca-cert \
#   --description "Perf test CA cert" \
#   --certificate "./cert/$EVENTGRID_FLOW_CLIENT_ID/ca_cert_upload.pem"

# az eventgrid namespace client create \
#   --resource-group $RESOURCE_GROUP \
#   --namespace-name $EVENTGRID_NAMESPACE \
#   -n $EVENTGRID_FLOW_CLIENT_ID \
#   --client-certificate-authentication "{validationScheme:SubjectMatchesAuthenticationName}"

az eventgrid namespace topic-space create --name perf-topic-space --namespace-name $EVENTGRID_NAMESPACE --resource-group $RESOURCE_GROUP --topic-template "[#]"

az eventgrid namespace permission-binding create \
  --name "perf-perm-binding" \
  --namespace-name $EVENTGRID_NAMESPACE \
  --resource-group $RESOURCE_GROUP \
  --topic-space-name "perf-topic-space" \
  --client-group-name "\$all" \
  --permission "Publisher"

# Add role bidnding for EventGrid TopicSpaces Publisher
export MANAGED_IDENTITY_CLIENT_ID=$(az identity show --name $USER_IDENTITY_NAME --resource-group $RESOURCE_GROUP --query principalId -o tsv)
az role assignment create --role "EventGrid TopicSpaces Publisher" --assignee $MANAGED_IDENTITY_CLIENT_ID --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.EventGrid/namespaces/$EVENTGRID_NAMESPACE"

# kubectl create secret -n azure-iot-operations generic eventgrid-secret --from-file=client_cert.pem=./cert/$EVENTGRID_FLOW_CLIENT_ID/device_ec_cert.pem --from-file=client_key.pem=./cert/$EVENTGRID_FLOW_CLIENT_ID/device_ec_key.pem