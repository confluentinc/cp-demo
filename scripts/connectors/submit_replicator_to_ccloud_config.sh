#!/bin/bash

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "replicate-topic-to-ccloud",
  "config": {
    "connector.class": "io.confluent.connect.replicator.ReplicatorSourceConnector",
    "topic.whitelist": "wikipedia.parsed",
    "topic.rename.format": "\${topic}.ccloud.replica",
    "key.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "dest.value.converter": "io.confluent.connect.avro.AvroConverter",
    "dest.value.converter.schema.registry.url": "${SCHEMA_REGISTRY_URL}",
    "dest.value.converter.basic.auth.credentials.source": "${BASIC_AUTH_CREDENTIALS_SOURCE}",
    "dest.value.converter.basic.auth.user.info": "${SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO}",
    "src.value.converter": "io.confluent.connect.avro.AvroConverter",
    "src.value.converter.schema.registry.url": "https://schemaregistry:8085",
    "src.value.converter.schema.registry.ssl.truststore.location": "/etc/kafka/secrets/kafka.client.truststore.jks",
    "src.value.converter.schema.registry.ssl.truststore.password": "confluent",
    "src.value.converter.basic.auth.credentials.source": "USER_INFO",
    "src.value.converter.basic.auth.user.info": "connectorSA:connectorSA",
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
    "consumer.override.sasl.jaas.config": "org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required username=\"connectorSA\" password=\"connectorSA\" metadataServerUrls=\"https://kafka1:8091,https://kafka2:8092\";",
    "tasks.max": "1",
    "provenance.header.enable": "true"
  }
}
EOF
)

docker-compose exec connect curl -X POST -H "${HEADER}" --data "${DATA}" --cert /etc/kafka/secrets/connect.certificate.pem --key /etc/kafka/secrets/connect.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u connectorSubmitter:connectorSubmitter https://connect:8083/connectors
