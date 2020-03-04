#!/bin/bash -e

################################## GET KAFKA CLUSTER ID ########################
ZK_CONTAINER=zookeeper
ZK_PORT=2181
KAFKA_CLUSTER_ID=$(zookeeper-shell $ZK_CONTAINER:$ZK_PORT get /cluster/id 2> /dev/null | grep \"version\" | jq -r .id)
if [ -z "$KAFKA_CLUSTER_ID" ]; then 
    echo "Failed to retrieve kafka cluster id from zookeeper"
    exit 1
fi

################################## SETUP VARIABLES #############################
MDS_URL=http://kafka1:8090
CONNECT=connect-cluster
SR=schema-registry
KSQL=ksql-cluster
C3=c3-cluster

SUPER_USER=professor
SUPER_USER_PASSWORD=professor
SUPER_USER_PRINCIPAL="User:$SUPER_USER"
CONNECT_PRINCIPAL="User:fry"
SR_PRINCIPAL="User:leela"
KSQL_PRINCIPAL="User:zoidberg"
C3_PRINCIPAL="User:hermes"

# Log into MDS
if [[ $(type expect 2>&1) =~ "not found" ]]; then
  echo "'expect' is not found. Install 'expect' and try again"
  exit 1
fi
echo -e "\n# Login"
OUTPUT=$(
expect <<END
  log_user 1
  spawn confluent login --url $MDS_URL
  expect "Username: "
  send "${SUPER_USER}\r";
  expect "Password: "
  send "${SUPER_USER_PASSWORD}\r";
  expect "Logged in as "
  set result $expect_out(buffer)
END
)
echo "$OUTPUT"
if [[ ! "$OUTPUT" =~ "Logged in as" ]]; then
  echo "Failed to log into your Metadata Server.  Please check all parameters and run again"
  exit 1
fi

################################### SETUP SUPERUSER ###################################
echo "Creating Super User role bindings"

confluent iam rolebinding create \
    --principal $SUPER_USER_PRINCIPAL  \
    --role SystemAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $SUPER_USER_PRINCIPAL \
    --role SystemAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --schema-registry-cluster-id $SR

confluent iam rolebinding create \
    --principal $SUPER_USER_PRINCIPAL \
    --role SystemAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --connect-cluster-id $CONNECT

confluent iam rolebinding create \
    --principal $SUPER_USER_PRINCIPAL \
    --role SystemAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --ksql-cluster-id $KSQL

################################### SCHEMA REGISTRY ###################################
echo "Creating Schema Registry role bindings"

# SecurityAdmin on SR cluster itself
confluent iam rolebinding create \
    --principal $SR_PRINCIPAL \
    --role SecurityAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --schema-registry-cluster-id $SR

# ResourceOwner for groups and topics on broker
for resource in Topic:_schemas Group:schema-registry
do
    confluent iam rolebinding create \
        --principal $SR_PRINCIPAL \
        --role ResourceOwner \
        --resource $resource \
        --kafka-cluster-id $KAFKA_CLUSTER_ID
done

################################### CONNECT ###################################
echo "Creating Connect role bindings"

# SecurityAdmin on the connect cluster itself
confluent iam rolebinding create \
    --principal $CONNECT_PRINCIPAL \
    --role SecurityAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --connect-cluster-id $CONNECT

# ResourceOwner for groups and topics on broker
declare -a ConnectResources=(
    "Topic:connect-configs" 
    "Topic:connect-offsets" 
    "Topic:connect-statuses" 
    "Topic:_confluent-secrets"
    "Group:connect-cluster" 
    "Group:secret-registry" 
)
for resource in ${ConnectResources[@]}
do
    confluent iam rolebinding create \
        --principal $CONNECT_PRINCIPAL \
        --role ResourceOwner \
        --resource $resource \
        --kafka-cluster-id $KAFKA_CLUSTER_ID
done

################################### KSQL ###################################
echo "Creating KSQL role bindings"

confluent iam rolebinding create \
    --principal $KSQL_PRINCIPAL \
    --role ResourceOwner \
    --resource KsqlCluster:ksql-cluster \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --ksql-cluster-id $KSQL

confluent iam rolebinding create \
    --principal $KSQL_PRINCIPAL \
    --role ResourceOwner \
    --resource Group:_confluent-ksql-${KSQL} \
    --prefix \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $KSQL_PRINCIPAL \
    --role ResourceOwner \
    --resource Topic:_confluent-ksql-${KSQL}_command_topic \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $KSQL_PRINCIPAL \
    --role ResourceOwner \
    --resource Topic:${KSQL}ksql_processing_log \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $KSQL_PRINCIPAL \
    --role ResourceOwner \
    --resource Topic:wikipedia.parsed \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $KSQL_PRINCIPAL \
    --role ResourceOwner \
    --resource Topic:WIKIPEDIA \
    --prefix \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $KSQL_PRINCIPAL \
    --role ResourceOwner \
    --resource Topic:EN_WIKIPEDIA \
    --prefix \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $KSQL_PRINCIPAL \
    --role ResourceOwner \
    --resource Subject:WIKIPEDIA \
    --prefix \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --schema-registry-cluster-id $SR

confluent iam rolebinding create \
    --principal $KSQL_PRINCIPAL \
    --role ResourceOwner \
    --resource Subject:EN_WIKIPEDIA \
    --prefix \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --schema-registry-cluster-id $SR

################################### Connector ###################################
echo "Creating role bindings for the connectors"

confluent iam rolebinding create \
    --principal $CONNECT_PRINCIPAL \
    --role ResourceOwner \
    --resource Connector:wikipedia-irc \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --connect-cluster-id $CONNECT

confluent iam rolebinding create \
    --principal $CONNECT_PRINCIPAL \
    --role ResourceOwner \
    --resource Connector:replicate-topic \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --connect-cluster-id $CONNECT

confluent iam rolebinding create \
    --principal $CONNECT_PRINCIPAL \
    --role ResourceOwner \
    --resource Connector:elasticsearch-ksql \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --connect-cluster-id $CONNECT

confluent iam rolebinding create \
    --principal $CONNECT_PRINCIPAL \
    --role ResourceOwner \
    --resource Topic:wikipedia \
    --prefix \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $CONNECT_PRINCIPAL \
    --role ResourceOwner \
    --resource Subject:wikipedia \
    --prefix \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --schema-registry-cluster-id $SR

################################### C3 ###################################
echo "Creating C3 role bindings"

# C3 only needs SystemAdmin on the kafka cluster itself
confluent iam rolebinding create \
    --principal $C3_PRINCIPAL \
    --role SystemAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID


######################### print cluster ids and users again to make it easier to copypaste ###########

echo "Cluster IDs:"
echo "    kafka cluster id: $KAFKA_CLUSTER_ID"
echo "    connect cluster id: $CONNECT"
echo "    schema registry cluster id: $SR"
echo "    ksql cluster id: $KSQL"
echo
echo "Cluster IDs as environment variables:"
echo "    export KAFKA_ID=$KAFKA_CLUSTER_ID ; export CONNECT_ID=$CONNECT ; export SR_ID=$SR ; export KSQL_ID=$KSQL"
echo
echo "Service accounts:"
echo "    super user account: $SUPER_USER_PRINCIPAL"
echo "    connect service account: $CONNECT_PRINCIPAL"
echo "    schema registry service account: $SR_PRINCIPAL"
echo "    KSQL service account: $KSQL_PRINCIPAL"
echo "    C3 service account: $C3_PRINCIPAL"

