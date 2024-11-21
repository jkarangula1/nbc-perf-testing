


# E2E Throughput Testing with 8kb Messages


## Setup

### Cluster Configuration:
- We used an AKS cluster with 5 nodes.
- Each node has 8 cores and 32 GiB of memory.
- `Standard_D8ds_v5`

### Traffic Generation:
- We used EMQTT bench inside a pod.
- 100 clients sent 35,000 messages per second, each 8kb in size.
- ```
  /emqtt_bench pub -c 100 -h  aio-broker -t source/%i -I 2 -s 8192 -q 1 -F 100 --payload-hdrs  ts

### Event Hub Configuration

- We used a Premium instance of Event Hub, 16 throughput units, 25 partitions.


