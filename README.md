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

# If you need to install emqtt_bench
sudo apt update
sudo apt upgrade
sudo apt install build-essential erlang cmake libatomic1 make
git clone https://github.com/emqx/emqtt-bench.git
cd emqtt-bench
git checkout 0.4.8
make

# Use this command to test the broker. With -I being the interval between messages, you can adjust clients to raise or lower by 1k messages per second.
#
# -F number of inflight messages
# -i interval between clients connecting
# -I interval between messages
# -c number of clients
./emqtt_bench pub -h 127.0.0.1 -p 11883 -t "source" -q 1 -F 100 -i 50 -c 40 -I 1 -m "{\"i=2258\":{\"Value\":\"2024-04-27T18:01:52.1865386Z\",\"SourceTimestamp\":\"2024-04-27T18:01:51.1647297Z\",\"ServerTimestamp\":\"2024-04-27T18:01:52.1865372Z\"},\"nsu=http://opcfoundation.org/UA/Plc/Applications;s=StepUp\":{\"Value\":108,\"SourceTimestamp\":\"2024-04-27T18:02:01.1415142Z\"}}"

# or
./emqtt_bench pub -h 127.0.0.1 -p 11883 -t "source" -q 1 -F 100 -i 50 -c 40 -I 1 -m "{\"value\": \"foo\"}"

```
