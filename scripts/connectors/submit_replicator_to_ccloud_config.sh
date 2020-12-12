#!/bin/bash

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
    "dest.kafka.bootstrap.servers": "${BOOTSTRAP_SERVERS}",
    "dest.kafka.security.protocol": "SASL_SSL",
    "dest.kafka.sasl.jaas.config": "org.apache.kafka.common.security.plain.PlainLoginModule required username=\"${API_KEY}\" password=\"${API_SECRET}\";",
    "dest.kafka.sasl.mechanism": "PLAIN",
    "dest.topic.replication.factor": 3,
    "confluent.topic.replication.factor": 3,
    "src.kafka.bootstrap.servers": "kafka1:10091",
    "src.kafka.security.protocol": "SASL_SSL",
    "src.kafka.ssl.key.password": "confluent",
    "src.kafka.ssl.truststore.location": "/etc/kafka/secrets/kafka.client.truststore.jks",
    "src.kafka.ssl.truststore.password": "confluent",
    "src.kafka.ssl.keystore.location": "/etc/kafka/secrets/kafka.client.keystore.jks",
    "src.kafka.ssl.keystore.password": "confluent",
    "src.kafka.sasl.login.callback.handler.class": "io.confluent.kafka.clients.plugins.auth.token.TokenUserLoginCallbackHandler",
    "src.kafka.sasl.jaas.config": "org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required username=\"connectorSA\" password=\"connectorSA\" metadataServerUrls=\"https://kafka1:8091,https://kafka2:8092\";",
    "src.kafka.sasl.mechanism": "OAUTHBEARER",
    "src.consumer.group.id": "connect-replicator",
    "offset.timestamps.commit": "false",
    "producer.override.bootstrap.servers": "${BOOTSTRAP_SERVERS}",
    "producer.override.security.protocol": "SASL_SSL",
    "producer.override.sasl.jaas.config": "org.apache.kafka.common.security.plain.PlainLoginModule required username=\"${API_KEY}\" password=\"${API_SECRET}\";",
    "producer.override.sasl.mechanism": "PLAIN",
    "consumer.override.sasl.jaas.config": "org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required username=\"connectorSA\" password=\"connectorSA\" metadataServerUrls=\"https://kafka1:8091,https://kafka2:8092\";",
    "tasks.max": "1",
    "provenance.header.enable": "true"
  }
}
EOF
)

docker-compose exec connect curl -X POST -H "${HEADER}" --data "${DATA}" --cert /etc/kafka/secrets/connect.certificate.pem --key /etc/kafka/secrets/connect.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u connectorSubmitter:connectorSubmitter https://connect:8083/connectors
