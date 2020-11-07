#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

config=$1
topic=$2

export KAFKA_LOG4J_OPTS="-Dlog4j.rootLogger=DEBUG,stdout -Dlog4j.logger.kafka=DEBUG,stdout" && kafka-topics \
   --bootstrap-server kafka1:11091 \
   --command-config /etc/kafka/secrets/$config \
   --topic $topic \
   --create \
   --replication-factor 2 \
   --partitions 2 \
   --config confluent.value.schema.validation=true
