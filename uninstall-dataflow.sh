#!/bin/bash

source .env

kubectl delete configmap aio-broker-ca
helm uninstall dataflows
