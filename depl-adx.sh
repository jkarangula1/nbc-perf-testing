#!/bin/bash

set -e

source .env

# az extension add -n kusto

az kusto cluster create --resource-group $RESOURCE_GROUP --name $ADX_CLUSTER_NAME --location $RESOURCE_LOCATION --enable-streaming-ingest true --sku name='Dev(No SLA)_Standard_D11_v2' capacity=1 tier=Basic
az kusto database create --cluster-name $ADX_CLUSTER_NAME --resource-group $RESOURCE_GROUP --database-name $ADX_DB_NAME --read-write-database location=$RESOURCE_LOCATION soft-delete-period=P1D

az deployment group create -n "deploy-$(uuidgen)" --resource-group $RESOURCE_GROUP --template-file "./adx/adx-table.bicep" --parameters clusterName=$ADX_CLUSTER_NAME databaseName=$ADX_DB_NAME scriptName=table-create

# TODO still needs the proper permissions for ingestion by the managed identity.
