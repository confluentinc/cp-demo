#!/bin/bash

CONNECT_HOST=localhost

if [[ $1 ]];then
    CONNECT_HOST=$1
fi

#    "topics": "WIKIPEDIABOT,EN_WIKIPEDIA_GT_1",
#    "topic.index.map": "WIKIPEDIABOT:wikipediabot,EN_WIKIPEDIA_GT_1:en_wikipedia_gt_1",

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
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": false,
    "transforms": "FilterNulls",
    "transforms.FilterNulls.type": "io.confluent.transforms.NullFilter",
    "schema.ignore": true

  }
}
EOF
)

echo "curl -X POST -H \"${HEADER}\" --data \"${DATA}\" http://${CONNECT_HOST}:8083/connectors"
curl -X POST -H "${HEADER}" --data "${DATA}" http://${CONNECT_HOST}:8083/connectors
echo
