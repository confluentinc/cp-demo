#!/bin/sh

docker exec cpdemo_connect_1 kafka-console-consumer --bootstrap-server kafka1:9092 --topic WIKIPEDIANOBOT \
  --consumer-property group.id=WIKIPEDIANOBOT-consumer \
  --consumer-property interceptor.classes=io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor \ \
  --consumer-property ssl.truststore.location=/etc/kafka/secrets/kafka.client.truststore.jks \
  --consumer-property ssl.truststore.password=confluent \
  --consumer-property ssl.keystore.location=/etc/kafka/secrets/kafka.client.keystore.jks \
  --consumer-property ssl.keystore.password=confluent --consumer-property ssl.key.password=confluent \
  --consumer-property confluent.monitoring.interceptor.security.protocol=ssl \
  --consumer-property confluent.monitoring.interceptor.ssl.truststore.location=/etc/kafka/secrets/kafka.client.truststore.jks \
  --consumer-property confluent.monitoring.interceptor.ssl.truststore.password=confluent \
  --consumer-property confluent.monitoring.interceptor.ssl.keystore.location=/etc/kafka/secrets/kafka.client.keystore.jks \
  --consumer-property confluent.monitoring.interceptor.ssl.keystore.password=confluent \
  --consumer-property confluent.monitoring.interceptor.ssl.key.password=confluent \
  --consumer-property security.protocol=SASL_SSL \
  --consumer-property sasl.jaas.config="org.apache.kafka.common.security.plain.PlainLoginModule required \
        username=\"client\" \
        password=\"client-secret\";" \
  --consumer-property sasl.mechanism=PLAIN > /dev/null 2>&1 &
