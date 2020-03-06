#!/bin/bash

# Usage
if [[ -z "$1" ]]; then
  echo "Usage: ./start_consumer_app.sh [id 1|2|3]"
  exit 1
fi

ID=$1


# Demo: for simplicity use PLAINTEXT port with superUser credentials

docker exec connect kafka-avro-console-consumer \
   --bootstrap-server kafka1:12091,kafka2:12092 \
   --property schema.registry.url=https://schemaregistry:8085 \
   --property schema.registry.ssl.truststore.location=/etc/kafka/secrets/kafka.kafka1.truststore.jks \
   --property schema.registry.ssl.truststore.password=confluent \
   --property basic.auth.credentials.source=USER_INFO \
   --property schema.registry.basic.auth.user.info=superUser:superUser \
   --consumer-property interceptor.classes=io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor \
   --consumer-property group.id=app \
   --topic wikipedia.parsed \
   --consumer-property client.id=consumer_app_$ID > /dev/null 2>&1 &
