#!/bin/bash

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "wikipedia-sse",
  "config": {
    "connector.class": "com.github.cjmatta.kafka.connect.sse.ServerSentEventsSourceConnector",
    "sse.uri": "https://stream.wikimedia.org/v2/stream/recentchange",
    "topic": "wikipedia.parsed",
    "transforms": "extractData, parseJSON",
    "transforms.extractData.type": "org.apache.kafka.connect.transforms.ExtractField\$Value",
    "transforms.extractData.field": "data",
    "transforms.parseJSON.type": "com.github.jcustenborder.kafka.connect.json.FromJson\$Value",
    "transforms.parseJSON.json.exclude.locations": "#/properties/log_params,#/properties/\$schema,#/\$schema",
    "transforms.parseJSON.json.schema.location": "Url",
    "transforms.parseJSON.json.schema.url": "https://raw.githubusercontent.com/wikimedia/mediawiki-event-schemas/master/jsonschema/mediawiki/recentchange/1.0.0.json",
    "transforms.parseJSON.json.schema.validation.enabled": "false",
    "producer.interceptor.classes": "io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter.schema.registry.url": "https://schemaregistry:8085",
    "value.converter.schema.registry.ssl.truststore.location": "/etc/kafka/secrets/kafka.client.truststore.jks",
    "value.converter.schema.registry.ssl.truststore.password": "confluent",
    "value.converter.basic.auth.credentials.source": "USER_INFO",
    "value.converter.basic.auth.user.info": "connectorSA:connectorSA",
    "producer.override.sasl.jaas.config": "org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required username=\"connectorSA\" password=\"connectorSA\" metadataServerUrls=\"https://kafka1:8091,https://kafka2:8092\";",
    "tasks.max": "1"
  }
}
EOF
)

docker-compose exec connect curl -X POST -H "${HEADER}" --data "${DATA}" --cert /etc/kafka/secrets/connect.certificate.pem --key /etc/kafka/secrets/connect.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u connectorSubmitter:connectorSubmitter https://connect:8083/connectors || exit 1
