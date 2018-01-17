#!/bin/bash

echo -e "\nPrinting one message from each of the following topics:"

echo -e "\nwikipedia.parsed:"
docker exec cpdemo_connect_1 kafka-avro-console-consumer --bootstrap-server kafka1:9091 --topic wikipedia.parsed \
  --max-messages 1 \
  --property schema.registry.url=https://schemaregistry:8082 \
  --consumer.config /etc/kafka/secrets/client_without_interceptors.config

echo -e "\nWIKIPEDIA:"
docker exec cpdemo_connect_1 kafka-avro-console-consumer --bootstrap-server kafka1:9091 --topic WIKIPEDIA \
  --max-messages 1 \
  --property schema.registry.url=https://schemaregistry:8082 \
  --consumer.config /etc/kafka/secrets/client_without_interceptors.config

echo -e "\nWIKIPEDIABOT:"
docker exec cpdemo_connect_1 kafka-avro-console-consumer --bootstrap-server kafka1:9091 --topic WIKIPEDIABOT \
  --max-messages 1 \
  --property schema.registry.url=https://schemaregistry:8082 \
  --consumer.config /etc/kafka/secrets/client_without_interceptors.config

echo -e "\nWIKIPEDIANOBOT:"
docker exec cpdemo_connect_1 kafka-avro-console-consumer --bootstrap-server kafka1:9091 --topic WIKIPEDIANOBOT \
  --max-messages 1 \
  --property schema.registry.url=https://schemaregistry:8082 \
  --consumer.config /etc/kafka/secrets/client_without_interceptors.config
