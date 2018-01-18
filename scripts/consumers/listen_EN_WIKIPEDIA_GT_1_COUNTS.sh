#!/bin/sh

docker exec cpdemo_connect_1 kafka-avro-console-consumer --bootstrap-server kafka1:9091 --topic EN_WIKIPEDIA_GT_1_COUNTS \
  --property schema.registry.url=https://schemaregistry:8082 \
  --consumer-property group.id=EN_WIKIPEDIA_GT_1_COUNTS-consumer \
  --consumer.config /etc/kafka/secrets/client_with_interceptors.config > /dev/null 2>&1 &
