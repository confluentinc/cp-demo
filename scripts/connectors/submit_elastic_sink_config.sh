#!/bin/bash

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "elasticsearch-ksql",
  "config": {
    "connector.class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
    "consumer.interceptor.classes": "io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor",
    "topics": "WIKIPEDIABOT",
    "topic.index.map": "WIKIPEDIABOT:wikipediabot",
    "connection.url": "http://elasticsearch:9200",
    "type.name": "wikichange",
    "key.ignore": true,
    "key.converter.schema.registry.url": "https://schemaregistry:8085",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter.schema.registry.url": "https://schemaregistry:8085",
    "value.converter.schema.registry.ssl.truststore.location": "/etc/kafka/secrets/kafka.client.truststore.jks",
    "value.converter.schema.registry.ssl.truststore.password": "confluent",
    "value.converter.schema.registry.ssl.keystore.location": "/etc/kafka/secrets/kafka.client.keystore.jks",
    "value.converter.schema.registry.ssl.keystore.password": "confluent",
    "value.converter.basic.auth.credentials.source": "USER_INFO",
    "value.converter.basic.auth.user.info": "connectUser:connectUser",
    "producer.override.sasl.jaas.config": "org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required username=\"connectUser\" password=\"connectUser\" metadataServerUrls=\"http://kafka1:8090\";",
    "schema.ignore": true

  }
}
EOF
)

docker-compose exec connect curl -X POST -H "${HEADER}" --data "${DATA}" --cert /etc/kafka/secrets/connect.certificate.pem --key /etc/kafka/secrets/connect.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u connectUser:connectUser https://connect:8083/connectors
