az provider register -n "Microsoft.ExtendedLocation"
az provider register -n "Microsoft.Kubernetes"
az provider register -n "Microsoft.KubernetesConfiguration"
az provider register -n "Microsoft.IoTOperations"
az provider register -n "Microsoft.DeviceRegistry"

az extension remove --name connectedk8s

curl -L -o connectedk8s-1.10.0-py2.py3-none-any.whl https://github.com/AzureArcForKubernetes/azure-cli-extensions/raw/refs/heads/connectedk8s/public/cli-extensions/connectedk8s-1.10.0-py2.py3-none-any.whl   
az extension add --upgrade --source connectedk8s-1.10.0-py2.py3-none-any.whl

az connectedk8s connect --name offline-scenario-arc -l westus2 --resource-group jaswanth4 --subscription 249c0d61-388d-45ad-ba35-f9899f4c1374 --enable-oidc-issuer --enable-workload-identity

az connectedk8s show --resource-group jaswanth4 --name  offline-scenario-arc --query oidcIssuerProfile.issuerUrl --output tsv

#sudo vim /etc/rancher/k3s/config.yaml

#kube-apiserver-arg:
# - service-account-issuer=<SERVICE_ACCOUNT_ISSUER>
# - service-account-max-token-expiration=24h

export OBJECT_ID=$(az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv)

az connectedk8s enable-features -n  offline-scenario-arc -g jaswanth4 --custom-locations-oid $OBJECT_ID --features cluster-connect custom-locations

#systemctl restart k3s
