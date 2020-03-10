#!/bin/sh

docker exec connect kafka-avro-console-consumer \
  --property schema.registry.url=https://schemaregistry:8085 \
  --property schema.registry.ssl.truststore.location=/etc/kafka/secrets/kafka.client.truststore.jks \
  --property schema.registry.ssl.truststore.password=confluent \
  --bootstrap-server kafka1:9091 --topic wikipedia.failed \
  --consumer.config /etc/kafka/secrets/client_without_interceptors.config
