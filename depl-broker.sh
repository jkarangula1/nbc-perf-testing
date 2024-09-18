#!/bin/bash

# set -eux

source .env

echo "Deploying the cert manager"

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.3/cert-manager.yaml

echo "Sleeping for 10 seconds to let cert manager populate"
sleep 10

kubectl apply -f ./mq/issuer.yaml
kubectl apply -f ./mq/ca.yaml

helm install --atomic aio-broker oci://mqbuilds.azurecr.io/helm/aio-broker --version $MQ_VERSION_TAG

echo "Sleeping for 10 seconds to let CRDs populate"
sleep 10

kubectl apply -f ./mq/mq.yaml
