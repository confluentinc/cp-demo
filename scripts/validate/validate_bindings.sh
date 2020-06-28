#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

source ../helper/functions.sh

################################## GET KAFKA CLUSTER ID ########################
KAFKA_CLUSTER_ID=$(curl -s http://localhost:8091/v1/metadata/id | jq -r ".id")
echo "KAFKA_CLUSTER_ID: $KAFKA_CLUSTER_ID"

################################## SETUP VARIABLES #############################
MDS_URL=http://kafka1:8091
CONNECT=connect-cluster
SR=schema-registry
KSQLDB=ksql-cluster
C3=c3-cluster

SUPER_USER=superUser
SUPER_USER_PASSWORD=superUser
SUPER_USER_PRINCIPAL="User:$SUPER_USER"
CONNECT_ADMIN="User:connectAdmin"
CONNECTOR_SUBMITTER="User:connectorSubmitter"
CONNECTOR_PRINCIPAL="User:connectorSA"
SR_PRINCIPAL="User:schemaregistryUser"
KSQLDB_ADMIN="User:ksqlDBAdmin"
KSQLDB_USER="User:ksqlDBUser"
C3_ADMIN="User:controlcenterAdmin"
REST_ADMIN="User:restAdmin"
CLIENT_PRINCIPAL="User:appSA"
BADAPP="User:badapp"
LISTEN_PRINCIPAL="User:clientListen"

docker-compose exec tools bash -c ". /tmp/helper/functions.sh ; mds_login $MDS_URL ${SUPER_USER} ${SUPER_USER_PASSWORD}"

################################## Run through permutations #############################

for p in $SUPER_USER_PRINCIPAL $CONNECT_ADMIN $CONNECTOR_SUBMITTER $CONNECTOR_PRINCIPAL $SR_PRINCIPAL $KSQLDB_ADMIN $KSQLDB_USER $C3_ADMIN $REST_ADMIN $CLIENT_PRINCIPAL $BADAPP $LISTEN_PRINCIPAL; do
  for c in " " " --schema-registry-cluster-id $SR" " --connect-cluster-id $CONNECT" " --ksql-cluster-id $KSQLDB"; do
    echo
    echo "Showing bindings for principal $p and --kafka-cluster-id $KAFKA_CLUSTER_ID $c"
    docker-compose exec tools confluent iam rolebinding list --principal $p --kafka-cluster-id $KAFKA_CLUSTER_ID $c
    echo
  done
done
