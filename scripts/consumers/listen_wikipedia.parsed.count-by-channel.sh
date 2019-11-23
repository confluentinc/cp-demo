#!/bin/bash

ARGS="--bootstrap-server kafka1:9091 --consumer.config /etc/kafka/secrets/client_without_interceptors.config"
if [[ ! -z "$1" && "$1" == "SSL" ]]; then
  ARGS="--bootstrap-server kafka1:11091 --consumer.config /etc/kafka/secrets/client_without_interceptors_ssl.config"
fi

docker exec connect kafka-avro-console-consumer \
  --property schema.registry.url=https://schemaregistry:8085 \
  --property schema.registry.ssl.truststore.location=/etc/kafka/secrets/kafka.client.truststore.jks \
  --property schema.registry.ssl.truststore.password=confluent \
  --property schema.registry.ssl.keystore.location=/etc/kafka/secrets/kafka.client.keystore.jks \
  --property schema.registry.ssl.keystore.password=confluent  \
  --property schema.registry.ssl.protocol=TLS \
  --topic wikipedia.parsed.count-by-channel --group=test $ARGS
