#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

################################## GET KAFKA CLUSTER ID ########################
KAFKA_CLUSTER_ID=$(curl -s https://localhost:8091/v1/metadata/id --tlsv1.2 --cacert ${DIR}/../security/snakeoil-ca-1.crt | jq -r ".id")
if [ -z "$KAFKA_CLUSTER_ID" ]; then
    echo "Failed to retrieve Kafka cluster id"
    exit 1
fi

################################## SETUP VARIABLES #############################
MDS_URL=https://kafka1:8091
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
KSQLDB_SERVER="User:controlCenterAndKsqlDBServer"
C3_ADMIN="User:controlcenterAdmin"
REST_ADMIN="User:restAdmin"
CLIENT_PRINCIPAL="User:appSA"
BADAPP="User:badapp"
LISTEN_PRINCIPAL="User:clientListen"

docker-compose exec tools bash -c ". /tmp/helper/functions.sh ; mds_login $MDS_URL ${SUPER_USER} ${SUPER_USER_PASSWORD}"

################################## Run through permutations #############################

for p in $SUPER_USER_PRINCIPAL $CONNECT_ADMIN $CONNECTOR_SUBMITTER $CONNECTOR_PRINCIPAL $SR_PRINCIPAL $KSQLDB_ADMIN $KSQLDB_USER $KSQLDB_SERVER $C3_ADMIN $REST_ADMIN $CLIENT_PRINCIPAL $BADAPP $LISTEN_PRINCIPAL; do
  for c in " " " --schema-registry-cluster-id $SR" " --connect-cluster-id $CONNECT" " --ksql-cluster-id $KSQLDB"; do
    echo
    echo "Showing bindings for principal $p and --kafka-cluster-id $KAFKA_CLUSTER_ID $c"
    docker-compose exec tools confluent-v1 iam rolebinding list --principal $p --kafka-cluster-id $KAFKA_CLUSTER_ID $c -o json
    echo
  done
done
