#!/bin/bash

docker exec cpdemo_connect_1 kafka-avro-console-consumer \
  --property schema.registry.url=http://schemaregistry:8081 \
  --bootstrap-server kafka1:9092 --topic wikipedia.parsed \
  --consumer.config /etc/kafka/secrets/client_without_interceptors.config
