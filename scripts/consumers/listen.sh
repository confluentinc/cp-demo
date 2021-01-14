#!/bin/bash

for t in wikipedia.parsed WIKIPEDIABOT WIKIPEDIANOBOT; do

  echo -e "\nSample message from Topic $t"
  docker exec connect kafka-avro-console-consumer --bootstrap-server kafka1:11091,kafka2:11092 \
    --topic wikipedia.parsed \
    --consumer-property group.id=listen-consumer \
    --consumer-property security.protocol=SSL \
    --consumer-property ssl.truststore.location=/etc/kafka/secrets/kafka.clientListen.truststore.jks \
    --consumer-property ssl.truststore.password=confluent \
    --consumer-property ssl.keystore.location=/etc/kafka/secrets/kafka.clientListen.keystore.jks \
    --consumer-property ssl.keystore.password=confluent \
    --consumer-property ssl.key.password=confluent \
    --property schema.registry.url=https://schemaregistry:8085 \
    --property schema.registry.ssl.truststore.location=/etc/kafka/secrets/kafka.clientListen.truststore.jks \
    --property schema.registry.ssl.truststore.password=confluent \
    --property basic.auth.credentials.source=USER_INFO \
    --property basic.auth.user.info=clientListen:clientListen \
    --max-messages 1

done
