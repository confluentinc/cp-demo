#!/bin/bash

echo -e "Sample message from different topics:"

echo -e "\nwikipedia.parsed:"
docker exec cpdemo_connect_1 kafka-avro-console-consumer --bootstrap-server kafka1:9091 --topic wikipedia.parsed \
  --property schema.registry.url=https://schemaregistry:8082 \
  --consumer.config /etc/kafka/secrets/client_without_interceptors.config --max-messages 1

echo -e "\nwikipedia.parsed.replica:"
docker exec cpdemo_connect_1 kafka-avro-console-consumer --bootstrap-server kafka1:9091 --topic wikipedia.parsed.replica \
  --property schema.registry.url=https://schemaregistry:8082 \
  --consumer.config /etc/kafka/secrets/client_without_interceptors.config --max-messages 1
  
echo -e "\nWIKIPEDIABOT:"
docker exec cpdemo_connect_1 kafka-avro-console-consumer --bootstrap-server kafka1:9091 --topic WIKIPEDIABOT \
  --property schema.registry.url=https://schemaregistry:8082 \
  --consumer.config /etc/kafka/secrets/client_without_interceptors.config --max-messages 1
  
echo -e "\nWIKIPEDIANOBOT:"
docker exec cpdemo_connect_1 kafka-avro-console-consumer --bootstrap-server kafka1:9091 --topic WIKIPEDIANOBOT \
  --property schema.registry.url=https://schemaregistry:8082 \
  --consumer.config /etc/kafka/secrets/client_without_interceptors.config --max-messages 1

echo -e "\nEN_WIKIPEDIA_GT_1_COUNTS:"
docker exec cpdemo_connect_1 kafka-avro-console-consumer --bootstrap-server kafka1:9091 --topic EN_WIKIPEDIA_GT_1_COUNTS \
  --property schema.registry.url=https://schemaregistry:8082 \
  --consumer.config /etc/kafka/secrets/client_without_interceptors.config --max-messages 1
