#!/bin/bash

# Create Kafka topic users, using appSA principal
docker-compose exec kafka1 bash -c 'export KAFKA_LOG4J_OPTS="-Dlog4j.rootLogger=DEBUG,stdout -Dlog4j.logger.kafka=DEBUG,stdout" && kafka-topics \
   --bootstrap-server kafka1:11091 \
   --command-config /etc/kafka/secrets/appSA.config \
   --topic users \
   --create \
   --replication-factor 2 \
   --partitions 2 \
   --config confluent.value.schema.validation=true'

# Create Kafka topics with prefix wikipedia, using connectorSA principal
docker-compose exec kafka1 bash -c 'export KAFKA_LOG4J_OPTS="-Dlog4j.rootLogger=DEBUG,stdout -Dlog4j.logger.kafka=DEBUG,stdout" && kafka-topics \
   --bootstrap-server kafka1:11091 \
   --command-config /etc/kafka/secrets/connectorSA_without_interceptors_ssl.config \
   --topic wikipedia.parsed \
   --create \
   --replication-factor 2 \
   --partitions 2 \
   --config confluent.value.schema.validation=true'
docker-compose exec kafka1 bash -c 'export KAFKA_LOG4J_OPTS="-Dlog4j.rootLogger=DEBUG,stdout -Dlog4j.logger.kafka=DEBUG,stdout" && kafka-topics \
   --bootstrap-server kafka1:11091 \
   --command-config /etc/kafka/secrets/connectorSA_without_interceptors_ssl.config \
   --topic wikipedia.parsed.count-by-channel \
   --create \
   --replication-factor 2 \
   --partitions 2'
docker-compose exec kafka1 bash -c 'export KAFKA_LOG4J_OPTS="-Dlog4j.rootLogger=DEBUG,stdout -Dlog4j.logger.kafka=DEBUG,stdout" && kafka-topics \
   --bootstrap-server kafka1:11091 \
   --command-config /etc/kafka/secrets/connectorSA_without_interceptors_ssl.config \
   --topic wikipedia.failed \
   --create \
   --replication-factor 2 \
   --partitions 2'

# Create Kafka topics with prefix WIKIPEDIA or EN_WIKIPEDIA, using ksqlDBUser principal
for t in WIKIPEDIABOT WIKIPEDIANOBOT EN_WIKIPEDIA_GT_1 EN_WIKIPEDIA_GT_1_COUNTS
do
  docker-compose exec kafka1 bash -c 'export KAFKA_LOG4J_OPTS="-Dlog4j.rootLogger=DEBUG,stdout -Dlog4j.logger.kafka=DEBUG,stdout" && kafka-topics \
     --bootstrap-server kafka1:11091 \
     --command-config /etc/kafka/secrets/ksqlDBUser_without_interceptors_ssl.config \
     --topic '"$t"' \
     --create \
     --replication-factor 2 \
     --partitions 2'
done
