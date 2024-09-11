# Performance Testing the NBC

Update the env vars in `.env` to fit your needs. Many of them can stay the same.

Make sure to run all of these in the same shell for env var reasons.

```bash
az login

# Deploy AKS
./depl-aks.sh

# Deploy MQ to get the broker cert deployed
./depl-mq.sh

# Pick which endpoint you are trying to test and deploy it
# Deploy an Eventhub
./depl-eventhub.sh
# Deploy a Datalake
./depl-datalake.sh
# Deploy an Event Grid
./depl-eventgrid.sh
# Deploy an Azure Data Explorer (ADX)

# If using an endpoint which needs a schema, set it in the DSS
# Make sure to check if the schema matches what you want to send
./dss.sh

# Deploy a dataflow (choose one)
./depl-dataflow.sh mq
./depl-dataflow.sh eventhub
./depl-dataflow.sh datalake
./depl-dataflow.sh eventgrid
./depl-dataflow.sh adx

# If testing locally, port forward a local port to the cluster
kubectl port-forward svc/aio-broker 11883:1883

```
