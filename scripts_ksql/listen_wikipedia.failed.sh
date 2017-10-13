#!/bin/sh

docker exec cpdemo_connect_1 kafka-console-consumer \
  --bootstrap-server kafka1:9092 --topic wikipedia.failed
