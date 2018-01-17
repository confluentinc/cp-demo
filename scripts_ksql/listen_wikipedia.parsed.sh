#!/bin/bash

ARGS="--bootstrap-server kafka1:9091 --consumer.config /etc/kafka/secrets/client_without_interceptors.config"
if [[ ! -z "$1" && "$1" == "SSL" ]]; then
  ARGS="--bootstrap-server kafka1:11091 --consumer.config /etc/kafka/secrets/client_without_interceptors_ssl.config"
fi

docker exec cpdemo_connect_1 kafka-console-consumer \
  --topic wikipedia.parsed --group=test $ARGS
