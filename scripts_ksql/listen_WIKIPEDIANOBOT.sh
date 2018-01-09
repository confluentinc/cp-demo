#!/bin/sh

docker exec cpdemo_connect_1 kafka-console-consumer --bootstrap-server kafka1:9091 --topic WIKIPEDIANOBOT \
  --consumer-property group.id=WIKIPEDIANOBOT-consumer \
  --consumer.config /etc/kafka/secrets/client_with_interceptors.config > /dev/null 2>&1 &
