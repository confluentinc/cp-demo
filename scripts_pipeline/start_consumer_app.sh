#!/bin/bash

# Usage
if [[ -z "$1" ]]; then
  echo "Usage: ./start_consumer_app.sh [id 1|2|3]"
  exit 1
fi

ID=$1

docker exec cpdemo_connect_1 kafka-avro-console-consumer \
  --property schema.registry.url=http://schemaregistry:8081 \
  --bootstrap-server kafka1:9092 --topic wikipedia.parsed \
  --consumer-property group.id=app --consumer-property client.id=consumer_app_$ID \
  --consumer.config /etc/kafka/secrets/client_with_interceptors.config > /dev/null 2>&1 &
