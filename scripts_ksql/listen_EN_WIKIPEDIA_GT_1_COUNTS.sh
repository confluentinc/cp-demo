#!/bin/sh

docker exec cpdemo_connect_1 kafka-console-consumer --bootstrap-server kafka1:9092 --topic EN_WIKIPEDIA_GT_1_COUNTS \
  --consumer-property group.id=EN_WIKIPEDIA_GT_1_COUNTS-consumer \
  --consumer.config /etc/kafka/secrets/client_with_interceptors.config > /dev/null 2>&1 &
