#!/bin/bash

ARGS="--consumer.config /etc/kafka/secrets/client_without_interceptors.config"
if [[ ! -z "$1" && "$1" == "badclient" ]]; then
  ARGS="--consumer.config /etc/kafka/secrets/badclient_without_interceptors.config --group=test"
fi

docker exec cpdemo_connect_1 kafka-console-consumer \
  --bootstrap-server kafka1:9091 --topic wikipedia.parsed $ARGS
