#!/bin/bash

ARGS="--consumer.config /etc/kafka/secrets/client_without_interceptors.config"
if [[ ! -z "$1" && "$1" == "badclient" ]]; then
  ARGS="--consumer.config /etc/kafka/secrets/badclient_without_interceptors.config --group=test"
fi

docker exec cpdemo_connect_1 kafka-avro-console-consumer \
  --property schema.registry.url=http://schemaregistry:8081 \
  --bootstrap-server kafka1:9091 --topic wikipedia.parsed $ARGS
