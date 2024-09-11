# Performance Testing the NBC

Update the env vars in `.env` to fit your needs. Many of them can stay the same.

Make sure to run all of these in the same shell for env var reasons.

```bash
az login

# Deploy AKS
./depl-aks.sh

# Deploy MQ to get the broker cert deployed
./depl-mq.sh

# Deploy an Eventhub
./depl-eventhub.sh

# Deploy a Datalake
./depl-datalake.sh
```
