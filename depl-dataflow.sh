#!/bin/bash

source .env

# Check if configmap aio-broker-ca exists
if $(kubectl get configmap aio-broker-ca -n default &> /dev/null); then
    echo "Configmap aio-broker-ca already exists."
else
    echo "Configmap aio-broker-ca does not exist. Creating it now."
    kubectl get secret test-ca -n default -o json | jq -r '.data["tls.crt"]' | base64 -d > ca.crt
    kubectl create configmap aio-broker-ca --from-file ca.crt=ca.crt
    rm ./ca.crt
fi

# Check if helm dataflows deployment exists
if ! $(helm list -n default | grep -q dataflows); then
    echo "Helm dataflows deployment does not exist. Installing it now."
    helm install --atomic dataflows ../one-connector/distrib/helm/DATAFLOWS --set image.containerRegistry=dwaltonacr.azurecr.io --set image.tag=kafkafix
    # helm install --atomic dataflows oci://mqbuilds.azurecr.io/helm/dataflows --version $DATAFLOW_VERSION_TAG

    echo "Sleeping for 10 seconds to let CRDs populate"
    sleep 10
else 
    echo "Helm dataflows deployment already exists."
fi

if [ "$1" == "mq" ]; then
    echo "Deploying the MQ-MQ dataflow"
    kubectl apply -f ./dataflow/mq-mq.yaml
elif [ "$1" == "adx" ]; then
    echo "Deploying the MQ-ADX dataflow"
    export MANAGED_IDENTITY_CLIENT_ID=$(az identity show --name "${USER_IDENTITY_NAME}" --resource-group "${RESOURCE_GROUP}" | jq -r .clientId)
    envsubst < dataflow/mq-adx.yaml | kubectl apply -f -
elif [ "$1" == "eventgrid" ]; then
    export MANAGED_IDENTITY_CLIENT_ID=$(az identity show --name "${USER_IDENTITY_NAME}" --resource-group "${RESOURCE_GROUP}" | jq -r .clientId)
    export EVENTGRID_MQTT_DOMAIN=$(az eventgrid namespace show --name $EVENTGRID_NAMESPACE --resource-group $RESOURCE_GROUP --query "topicSpacesConfiguration.hostname" -o tsv)
    envsubst < dataflow/mq-eventgrid.yaml | kubectl apply -f -
elif [ "$1" == "eventhub" ]; then
    export EVENTHUB_KAFKA_DOMAIN=$(az eventhubs namespace show --resource-group $RESOURCE_GROUP --namespace-name $EVENTHUB_NAMESPACE --query "serviceBusEndpoint" | sed -e 's/https:\/\///g' | sed 's/:443\//:9093/g')
    envsubst < dataflow/mq-eventhub.yaml | kubectl apply -f -
elif [ "$1" == "datalake" ]; then
    echo "Deploying the MQ-Datalake dataflow"
    export MANAGED_IDENTITY_CLIENT_ID=$(az identity show --name "${USER_IDENTITY_NAME}" --resource-group "${RESOURCE_GROUP}" | jq -r .clientId)
    envsubst < dataflow/mq-datalake.yaml | kubectl apply -f -
else
    echo "No dataflow specified"
    exit 1
fi
