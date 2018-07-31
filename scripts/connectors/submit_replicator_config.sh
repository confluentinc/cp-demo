#!/bin/bash

CONNECT_HOST=localhost

if [[ $1 ]];then
    CONNECT_HOST=$1
fi

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "replicate-topic",
  "config": {
    "connector.class": "io.confluent.connect.replicator.ReplicatorSourceConnector",
    "topic.whitelist": "wikipedia.parsed",
    "topic.rename.format": "\${topic}.replica",
    "key.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "value.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "dest.kafka.bootstrap.servers": "kafka1:9091",
    "dest.kafka.security.protocol": "SASL_SSL",
    "dest.kafka.ssl.key.password": "confluent",
    "dest.kafka.ssl.truststore.location": "/etc/kafka/secrets/kafka.client.truststore.jks",
    "dest.kafka.ssl.truststore.password": "confluent",
    "dest.kafka.ssl.keystore.location": "/etc/kafka/secrets/kafka.client.keystore.jks",
    "dest.kafka.ssl.keystore.password": "confluent",
    "dest.kafka.sasl.jaas.config": "org.apache.kafka.common.security.plain.PlainLoginModule required username=\"client\" password=\"client-secret\";",
    "dest.kafka.sasl.mechanism": "PLAIN",
    "dest.kafka.replication.factor": 2,
    "src.kafka.bootstrap.servers": "kafka1:9091",
    "src.kafka.security.protocol": "SASL_SSL",
    "src.kafka.ssl.key.password": "confluent",
    "src.kafka.ssl.truststore.location": "/etc/kafka/secrets/kafka.client.truststore.jks",
    "src.kafka.ssl.truststore.password": "confluent",
    "src.kafka.ssl.keystore.location": "/etc/kafka/secrets/kafka.client.keystore.jks",
    "src.kafka.ssl.keystore.password": "confluent",
    "src.kafka.sasl.jaas.config": "org.apache.kafka.common.security.plain.PlainLoginModule required username=\"client\" password=\"client-secret\";",
    "src.kafka.sasl.mechanism": "PLAIN",
    "src.consumer.interceptor.classes": "io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor",
    "src.consumer.confluent.monitoring.interceptor.security.protocol": "SASL_SSL",
    "src.consumer.confluent.monitoring.interceptor.bootstrap.servers": "kafka1:9091",
    "src.consumer.confluent.monitoring.interceptor.ssl.key.password": "confluent",
    "src.consumer.confluent.monitoring.interceptor.ssl.truststore.location": "/etc/kafka/secrets/kafka.client.truststore.jks",
    "src.consumer.confluent.monitoring.interceptor.ssl.truststore.password": "confluent",
    "src.consumer.confluent.monitoring.interceptor.ssl.keystore.location": "/etc/kafka/secrets/kafka.client.keystore.jks",
    "src.consumer.confluent.monitoring.interceptor.ssl.keystore.password": "confluent",
    "src.consumer.confluent.monitoring.interceptor.sasl.jaas.config": "org.apache.kafka.common.security.plain.PlainLoginModule required username=\"client\" password=\"client-secret\";",
    "src.consumer.confluent.monitoring.interceptor.sasl.mechanism": "PLAIN",   
    "src.consumer.group.id": "connect-replicator",
    "src.kafka.timestamps.producer.interceptor.classes": "io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor",
    "src.kafka.timestamps.producer.confluent.monitoring.interceptor.security.protocol": "SASL_SSL",
    "src.kafka.timestamps.producer.confluent.monitoring.interceptor.bootstrap.servers": "kafka1:9091",
    "src.kafka.timestamps.producer.confluent.monitoring.interceptor.ssl.key.password": "confluent",
    "src.kafka.timestamps.producer.confluent.monitoring.interceptor.ssl.truststore.location": "/etc/kafka/secrets/kafka.client.truststore.jks",
    "src.kafka.timestamps.producer.confluent.monitoring.interceptor.ssl.truststore.password": "confluent",
    "src.kafka.timestamps.producer.confluent.monitoring.interceptor.ssl.keystore.location": "/etc/kafka/secrets/kafka.client.keystore.jks",
    "src.kafka.timestamps.producer.confluent.monitoring.interceptor.ssl.keystore.password": "confluent",
    "src.kafka.timestamps.producer.confluent.monitoring.interceptor.sasl.jaas.config": "org.apache.kafka.common.security.plain.PlainLoginModule required username=\"client\" password=\"client-secret\";",
    "src.kafka.timestamps.producer.confluent.monitoring.interceptor.sasl.mechanism": "PLAIN",
    "tasks.max": "1"
  }
}
EOF
)

echo "curl -X POST -H \"${HEADER}\" --data \"${DATA}\" http://${CONNECT_HOST}:8083/connectors"
curl -X POST -H "${HEADER}" --data "${DATA}" http://${CONNECT_HOST}:8083/connectors
echo
