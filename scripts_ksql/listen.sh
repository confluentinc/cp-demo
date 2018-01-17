#!/bin/bash

echo -e "Sample of messages from different topics:"

echo -e "\nwikipedia.parsed:"
docker exec cpdemo_connect_1 kafka-console-consumer --bootstrap-server kafka1:9091 --topic wikipedia.parsed \
  --consumer.config /etc/kafka/secrets/client_without_interceptors.config --max-messages 1
  
echo -e "\nWIKIPEDIA:"
docker exec cpdemo_connect_1 kafka-console-consumer --bootstrap-server kafka1:9091 --topic WIKIPEDIA \
  --consumer.config /etc/kafka/secrets/client_without_interceptors.config --max-messages 1
  
echo -e "\nWIKIPEDIABOT:"
docker exec cpdemo_connect_1 kafka-console-consumer --bootstrap-server kafka1:9091 --topic WIKIPEDIABOT \
  --consumer.config /etc/kafka/secrets/client_without_interceptors.config --max-messages 1
  
echo -e "\nWIKIPEDIANOBOT:"
docker exec cpdemo_connect_1 kafka-console-consumer --bootstrap-server kafka1:9091 --topic WIKIPEDIANOBOT \
  --consumer.config /etc/kafka/secrets/client_without_interceptors.config --max-messages 1

echo -e "\nEN_WIKIPEDIA_GT_1_COUNTS:"
docker exec cpdemo_connect_1 kafka-console-consumer --bootstrap-server kafka1:9091 --topic EN_WIKIPEDIA_GT_1_COUNTS \
  --consumer.config /etc/kafka/secrets/client_without_interceptors.config --max-messages 1
