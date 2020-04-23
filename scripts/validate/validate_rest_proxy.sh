#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

################################## GET KAFKA CLUSTER ID ########################
KAFKA_CLUSTER_ID=$(curl -s http://localhost:8091/v1/metadata/id | jq -r ".id")
if [ -z "$KAFKA_CLUSTER_ID" ]; then
    echo "Failed to retrieve Kafka cluster id"
    exit 1
fi

################################## SETUP VARIABLES #############################
CONNECT=connect-cluster
SR=schema-registry
KSQLDB=ksql-cluster
C3=c3-cluster

CONNECT_ADMIN="User:connectAdmin"
CONNECTOR_SUBMITTER="User:connectorSubmitter"
CONNECTOR_PRINCIPAL="User:connectorSA"
SR_PRINCIPAL="User:schemaregistryUser"
KSQLDB_ADMIN="User:ksqlDBAdmin"
KSQLDB_USER="User:ksqlDBUser"
C3_ADMIN="User:controlcenterAdmin"
CLIENT_NAME="appSA"
CLIENT_PRINCIPAL="User:$CLIENT_NAME"

${DIR}/../helper/refresh_mds_login.sh

################################## RUN ########################################

topic="users"
subject="$topic-value"
group="my_avro_consumer"

docker-compose exec tools bash -c "confluent iam rolebinding create \
    --principal $CLIENT_PRINCIPAL \
    --role ResourceOwner \
    --resource Subject:$subject \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --schema-registry-cluster-id $SR"

# Register a new Avro schema for topic 'users'
docker-compose exec schemaregistry curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --cert /etc/kafka/secrets/schemaregistry.certificate.pem --key /etc/kafka/secrets/schemaregistry.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt --data '{ "schema": "[ { \"type\":\"record\", \"name\":\"user\", \"fields\": [ {\"name\":\"userid\",\"type\":\"long\"}, {\"name\":\"username\",\"type\":\"string\"} ]} ]" }' -u $CLIENT_NAME:$CLIENT_NAME https://schemaregistry:8085/subjects/$subject/versions

# Get the Avro schema id
schemaid=$(docker-compose exec schemaregistry curl -X GET --cert /etc/kafka/secrets/schemaregistry.certificate.pem --key /etc/kafka/secrets/schemaregistry.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u $CLIENT_NAME:$CLIENT_NAME https://schemaregistry:8085/subjects/$subject/versions/1 | jq '.id')

# Go through steps at https://docs.confluent.io/current/tutorials/cp-demo/docs/index.html?utm_source=github&utm_medium=demo&utm_campaign=ch.cp-demo_type.community_content.cp-demo#confluent-rest-proxy

docker-compose exec tools bash -c "confluent iam rolebinding create \
    --principal $CLIENT_PRINCIPAL \
    --role DeveloperWrite \
    --resource Topic:$topic \
    --kafka-cluster-id $KAFKA_CLUSTER_ID"

docker-compose exec restproxy curl -X POST -H "Content-Type: application/vnd.kafka.avro.v2+json" -H "Accept: application/vnd.kafka.v2+json" --cert /etc/kafka/secrets/restproxy.certificate.pem --key /etc/kafka/secrets/restproxy.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt --data '{"value_schema_id": '"$schemaid"', "records": [{"value": {"user":{"userid": 1, "username": "Bunny Smith"}}}]}' -u $CLIENT_NAME:$CLIENT_NAME https://restproxy:8086/topics/$topic

docker-compose exec restproxy curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" --cert /etc/kafka/secrets/restproxy.certificate.pem --key /etc/kafka/secrets/restproxy.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt --data '{"name": "my_consumer_instance", "format": "avro", "auto.offset.reset": "earliest"}' -u $CLIENT_NAME:$CLIENT_NAME https://restproxy:8086/consumers/$group

docker-compose exec restproxy curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" --cert /etc/kafka/secrets/restproxy.certificate.pem --key /etc/kafka/secrets/restproxy.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt --data '{"topics":["users"]}' -u $CLIENT_NAME:$CLIENT_NAME https://restproxy:8086/consumers/$group/instances/my_consumer_instance/subscription

docker-compose exec tools bash -c "confluent iam rolebinding create \
    --principal $CLIENT_PRINCIPAL \
    --role ResourceOwner \
    --resource Group:$group \
    --kafka-cluster-id $KAFKA_CLUSTER_ID"

docker-compose exec tools bash -c "confluent iam rolebinding create \
    --principal $CLIENT_PRINCIPAL \
    --role DeveloperRead \
    --resource Topic:$topic \
    --kafka-cluster-id $KAFKA_CLUSTER_ID"

# Note: Issue this command twice due to https://github.com/confluentinc/kafka-rest/issues/432
docker-compose exec restproxy curl -X GET -H "Accept: application/vnd.kafka.avro.v2+json" --cert /etc/kafka/secrets/restproxy.certificate.pem --key /etc/kafka/secrets/restproxy.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u $CLIENT_NAME:$CLIENT_NAME https://restproxy:8086/consumers/$group/instances/my_consumer_instance/records
output=$(docker-compose exec restproxy curl -X GET -H "Accept: application/vnd.kafka.avro.v2+json" --cert /etc/kafka/secrets/restproxy.certificate.pem --key /etc/kafka/secrets/restproxy.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u $CLIENT_NAME:$CLIENT_NAME https://restproxy:8086/consumers/$group/instances/my_consumer_instance/records)
if [[ $output =~ "Bunny Smith" ]]; then
  printf "\nPASS: Output $output matches expected output"
else
  printf "\nFAIL: Output $output does not match expected output"
fi

docker-compose exec restproxy curl -X DELETE -H "Content-Type: application/vnd.kafka.v2+json" --cert /etc/kafka/secrets/restproxy.certificate.pem --key /etc/kafka/secrets/restproxy.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u $CLIENT_NAME:$CLIENT_NAME https://restproxy:8086/consumers/$group/instances/my_consumer_instance

