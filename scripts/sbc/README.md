# cp-demo Self Balancing Clusters

The scripts in this directory demonstrate Confluent Platform's [Self Balancing Clusters (SBC)](https://docs.confluent.io/platform/current/kafka/sbc/index.html) features by adding a broker and triggering a rebalance, and failing a broker and triggering self-healing.

Run these scripts after the initial cp-demo start-up completes:

- `./scripts/sbc/add-broker.sh`: adds a 3rd broker to the cluster, triggering automatic rebalancing and relocating existing topic partitions to the new broker.
- `./scripts/sbc/kill-broker.sh`: simulates a failure of that 3rd broker, triggering self-healing to reassign its partitions to the remaining two brokers.
