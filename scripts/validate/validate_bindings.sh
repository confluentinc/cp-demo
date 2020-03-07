#!/bin/bash

################################## GET KAFKA CLUSTER ID ########################
KAFKA_CLUSTER_ID=$(docker-compose exec zookeeper zookeeper-shell zookeeper:2181 get /cluster/id 2> /dev/null | grep \"version\" | jq -r .id)
if [ -z "$KAFKA_CLUSTER_ID" ]; then
    echo "Failed to retrieve Kafka cluster id from ZooKeeper"
    exit 1
fi

################################## SETUP VARIABLES #############################
MDS_URL=http://kafka1:8091
CONNECT=connect-cluster
SR=schema-registry
KSQL=ksql-cluster
C3=c3-cluster

SUPER_USER=superUser
SUPER_USER_PASSWORD=superUser
SUPER_USER_PRINCIPAL="User:$SUPER_USER"
CONNECT_ADMIN="User:connectAdmin"
CONNECTOR_SUBMITTER="User:connectorSubmitter"
CONNECTOR_PRINCIPAL="User:connectorSA"
SR_PRINCIPAL="User:schemaregistryUser"
KSQL_ADMIN="User:ksqlAdmin"
KSQL_USER="User:ksqlUser"
C3_ADMIN="User:controlcenterAdmin"
CLIENT_PRINCIPAL="User:appSA"
BADAPP="User:badapp"

################################## Run through permutations #############################

for p in $SUPER_USER_PRINCIPAL $CONNECT_ADMIN $CONNECTOR_SUBMITTER $CONNECTOR_PRINCIPAL $SR_PRINCIPAL $KSQL_ADMIN $KSQL_USER $C3_ADMIN $CLIENT_PRINCIPAL $BADAPP; do
  for c in " " " --schema-registry-cluster-id $SR" " --connect-cluster-id $CONNECT" " --ksql-cluster-id $KSQL"; do
    echo
    echo "Showing bindings for principal $p and --kafka-cluster-id $KAFKA_CLUSTER_ID $c"
    docker-compose exec tools confluent iam rolebinding list --principal $p --kafka-cluster-id $KAFKA_CLUSTER_ID $c
    echo
  done
done
