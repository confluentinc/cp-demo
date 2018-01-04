#!/bin/bash

docker exec cpdemo_connect_1 kafka-avro-console-consumer \
  --property schema.registry.url=http://schemaregistry:8081 \
  --bootstrap-server kafka1:9092 --topic wikipedia.parsed \
  --consumer-property ssl.truststore.location=/etc/kafka/secrets/kafka.client.truststore.jks \
  --consumer-property ssl.truststore.password=confluent \
  --consumer-property ssl.keystore.location=/etc/kafka/secrets/kafka.client.keystore.jks \
  --consumer-property ssl.keystore.password=confluent --consumer-property ssl.key.password=confluent \
  --consumer-property security.protocol=SASL_SSL \
  --consumer-property sasl.jaas.config="org.apache.kafka.common.security.plain.PlainLoginModule required \
        username=\"client\" \
        password=\"client-secret\";" \
  --consumer-property sasl.mechanism=PLAIN
