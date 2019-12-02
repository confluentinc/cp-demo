#!/bin/sh

docker exec connect kafka-avro-console-consumer --bootstrap-server kafka1:9091 --topic WIKIPEDIANOBOT \
  --property schema.registry.url=https://schemaregistry:8085 \
  --property schema.registry.ssl.truststore.location=/etc/kafka/secrets/kafka.client.truststore.jks \
  --property schema.registry.ssl.truststore.password=confluent \
  --property schema.registry.ssl.keystore.location=/etc/kafka/secrets/kafka.client.keystore.jks \
  --property schema.registry.ssl.keystore.password=confluent  \
  --consumer-property group.id=WIKIPEDIANOBOT-consumer \
  --consumer.config /etc/kafka/secrets/client_with_interceptors.config > /dev/null 2>&1 &
