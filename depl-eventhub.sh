#!/bin/bash

set -ux

source .env

# Deploy the Event Hub namespace and instance
az eventhubs namespace create \
  --name $EVENTHUB_NAMESPACE \
  --resource-group $RESOURCE_GROUP \
  --location $RESOURCE_LOCATION \
  --sku Standard

az eventhubs eventhub create \
  --name $EVENTHUB_NAME \
  --namespace-name $EVENTHUB_NAMESPACE \
  --resource-group $RESOURCE_GROUP \
  --partition-count 25

# Create the access policy for NBC and create the secret in the cluster
az eventhubs eventhub authorization-rule create \
  --resource-group $RESOURCE_GROUP \
  --namespace-name $EVENTHUB_NAMESPACE \
  --eventhub-name $EVENTHUB_NAME \
  --name $EVENTHUB_ACCESS_POLICY_NAME \
  --rights Send Listen

az eventhubs eventhub authorization-rule keys list \
  --resource-group $RESOURCE_GROUP \
  --namespace-name $EVENTHUB_NAMESPACE \
  --eventhub-name $EVENTHUB_NAME \
  --name $EVENTHUB_ACCESS_POLICY_NAME \
  --output table


kubectl delete secret eh-secret
az eventhubs eventhub authorization-rule keys list \
  --resource-group $RESOURCE_GROUP \
  --namespace-name $EVENTHUB_NAMESPACE \
  --eventhub-name $EVENTHUB_NAME \
  --name $EVENTHUB_ACCESS_POLICY_NAME \
  --query "primaryConnectionString" \
  | xargs -d '\n' -I {} sh -c 'kubectl create secret generic eh-secret --from-literal=username="\$ConnectionString" --from-literal=password={}'


# ./emqtt_bench sub -c 100 -h aio-broker  -t source/%i   -q 1 --payload-hdrs  ts
# ./emqtt_bench pub -c 100 -h  aio-broker -t source/%i -I 2 -s 8192 -q 1 -F 100 --payload-hdrs  ts