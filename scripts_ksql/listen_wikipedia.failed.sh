#!/bin/sh

docker exec cpdemo_connect_1 kafka-console-consumer \
  --bootstrap-server kafka1:9091 --topic wikipedia.failed \
  --consumer.config /etc/kafka/secrets/client_without_interceptors.config
