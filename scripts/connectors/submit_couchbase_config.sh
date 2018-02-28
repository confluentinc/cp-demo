#!/bin/bash

CONNECT_HOST=localhost

if [[ $1 ]];then
    CONNECT_HOST=$1
fi

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "wiki-couchbase",
  "config":{
    "connector.class": "com.couchbase.connect.kafka.CouchbaseSinkConnector",
    "topics": "WIKIPEDIAJSON",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": false,
    "connection.cluster_address": "couchbase",
    "connection.bucket": "wikipedia",
    "connection.username": "kafka-connect",
    "connection.password": "password"
  }
}
EOF
)

echo "curl -X POST -H \"${HEADER}\" --data \"${DATA}\" http://${CONNECT_HOST}:8083/connectors"
curl -X POST -H "${HEADER}" --data "${DATA}" http://${CONNECT_HOST}:8083/connectors
echo

