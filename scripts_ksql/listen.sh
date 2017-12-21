#!/bin/bash

docker exec cpdemo_connect_1 kafka-console-consumer --bootstrap-server kafka1:9092 --topic wikipedia.parsed --max-messages 1 \
  --consumer-property security.protocol=ssl \
  --consumer-property ssl.truststore.location=/etc/kafka/secrets/kafka.client.truststore.jks \
  --consumer-property ssl.truststore.password=confluent \
  --consumer-property ssl.keystore.location=/etc/kafka/secrets/kafka.client.keystore.jks \
  --consumer-property ssl.keystore.password=confluent --consumer-property ssl.key.password=confluent
docker exec cpdemo_connect_1 kafka-console-consumer --bootstrap-server kafka1:9092 --topic WIKIPEDIA --max-messages 1 \
  --consumer-property security.protocol=ssl \
  --consumer-property ssl.truststore.location=/etc/kafka/secrets/kafka.client.truststore.jks \
  --consumer-property ssl.truststore.password=confluent \
  --consumer-property ssl.keystore.location=/etc/kafka/secrets/kafka.client.keystore.jks \
  --consumer-property ssl.keystore.password=confluent --consumer-property ssl.key.password=confluent
docker exec cpdemo_connect_1 kafka-console-consumer --bootstrap-server kafka1:9092 --topic WIKIPEDIABOT --max-messages 1 \
  --consumer-property security.protocol=ssl \
  --consumer-property ssl.truststore.location=/etc/kafka/secrets/kafka.client.truststore.jks \
  --consumer-property ssl.truststore.password=confluent \
  --consumer-property ssl.keystore.location=/etc/kafka/secrets/kafka.client.keystore.jks \
  --consumer-property ssl.keystore.password=confluent --consumer-property ssl.key.password=confluent
docker exec cpdemo_connect_1 kafka-console-consumer --bootstrap-server kafka1:9092 --topic WIKIPEDIANOBOT --max-messages 1 \
  --consumer-property security.protocol=ssl \
  --consumer-property ssl.truststore.location=/etc/kafka/secrets/kafka.client.truststore.jks \
  --consumer-property ssl.truststore.password=confluent \
  --consumer-property ssl.keystore.location=/etc/kafka/secrets/kafka.client.keystore.jks \
  --consumer-property ssl.keystore.password=confluent --consumer-property ssl.key.password=confluent
