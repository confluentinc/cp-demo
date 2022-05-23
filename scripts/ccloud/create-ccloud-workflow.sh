#!/bin/bash

VALIDATE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

source ${VALIDATE_DIR}/../helper/functions.sh
source ${VALIDATE_DIR}/../../.env
source ${VALIDATE_DIR}/../env.sh

verify_installed confluent || exit 1

curl -sS -o ccloud_library.sh https://raw.githubusercontent.com/confluentinc/examples/latest/utils/ccloud_library.sh
source ./ccloud_library.sh
ccloud::prompt_continue_ccloud_demo || exit 1

# Log into Confluent CLI
echo
confluent login --save || exit 1

# Create a new ccloud-stack
echo
echo "Configuring a new Confluent Cloud ccloud-stack (including a new Confluent Cloud ksqlDB application)"
echo "Note: real Confluent Cloud resources will be created and you are responsible for destroying them."
echo

export EXAMPLE="cp-demo"
ccloud::create_ccloud_stack true || exit 1
export SERVICE_ACCOUNT_ID=$(ccloud:get_service_account_from_current_cluster_name)
CONFIG_FILE=stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config
CCLOUD_CLUSTER_ID=$(confluent kafka cluster list -o json | jq -c -r '.[] | select (.name == "'"demo-kafka-cluster-$SERVICE_ACCOUNT_ID"'")' | jq -r .id)

# Create parameters customized for Confluent Cloud instance created above
ccloud::generate_configs $CONFIG_FILE
source "delta_configs/env.delta"

echo
echo "Sleep an additional 90s to wait for all Confluent Cloud metadata to propagate"
sleep 90

## TODO: Replace with cluster linking and schema linking
# echo -e "\nStart Confluent Replicator to Confluent Cloud:"
# CONNECTOR_SUBMITTER="User:connectorSubmitter"
# KAFKA_CLUSTER_ID=$(curl -s https://localhost:8091/v1/metadata/id --tlsv1.2 --cacert ${VALIDATE_DIR}/../security/snakeoil-ca-1.crt | jq -r ".id")
# CONNECT=connect-cluster
# ${VALIDATE_DIR}/../helper/refresh_mds_login.sh
# docker-compose exec tools bash -c "confluent iam rbac role-binding create \
#     --principal $CONNECTOR_SUBMITTER \
#     --role ResourceOwner \
#     --resource Connector:replicate-topic-to-ccloud \
#     --kafka-cluster-id $KAFKA_CLUSTER_ID \
#     --connect-cluster-id $CONNECT"
# ${VALIDATE_DIR}/../connectors/submit_replicator_to_ccloud_config.sh

# # Verify Replicator to Confluent Cloud has started
# echo
# echo
# MAX_WAIT=120
# echo "Waiting up to $MAX_WAIT seconds for Replicator to Confluent Cloud to start"
# retry $MAX_WAIT check_connector_status_running replicate-topic-to-ccloud || exit 1
# echo "Replicator started!"

# Create credentials for the cloud resource
echo
CREDENTIALS=$(confluent api-key create --resource cloud -o json) || exit 1
export METRICS_API_KEY=$(echo "$CREDENTIALS" | jq -r .key)
export METRICS_API_SECRET=$(echo "$CREDENTIALS" | jq -r .secret)

# Enable Confluent Telemetry Reporter
echo
echo "Enabling Confluent Telemetry Reporter cluster-wide to send metrics to Confluent Cloud"
docker-compose exec kafka1 kafka-configs \
  --bootstrap-server kafka1:12091 \
  --alter \
  --entity-type brokers \
  --entity-default \
  --add-config confluent.telemetry.enabled=true,confluent.telemetry.api.key=${METRICS_API_KEY},confluent.telemetry.api.secret=${METRICS_API_SECRET}

echo
echo "Sleeping 90s to wait for metrics collection to begin"
sleep 90

# Query Metrics API

CURRENT_TIME_MINUS_1HR=$(docker-compose exec tools date -Is -d '-1 hour' | tr -d '\r')
CURRENT_TIME_PLUS_1HR=$(docker-compose exec tools date -Is -d '+1 hour' | tr -d '\r')
echo
echo "CURRENT_TIME_MINUS_1HR=$CURRENT_TIME_MINUS_1HR"
echo "CURRENT_TIME_PLUS_1HR=$CURRENT_TIME_PLUS_1HR"
echo

# On-prem
DATA=$(eval "cat <<EOF       
$(<${VALIDATE_DIR}/metrics_query_onprem.json)
EOF
")
echo "DATA: $DATA"
curl -s -u ${METRICS_API_KEY}:${METRICS_API_SECRET} \
     --header 'content-type: application/json' \
     --data "${DATA}" \
     https://api.telemetry.confluent.cloud/v2/metrics/hosted-monitoring/query \
        | jq .

# Confluent Cloud
DATA=$(eval "cat <<EOF       
$(<${VALIDATE_DIR}/metrics_query_ccloud.json)
EOF
")
echo "DATA: $DATA"
curl -s -u ${METRICS_API_KEY}:${METRICS_API_SECRET} \
     --header 'content-type: application/json' \
     --data "${DATA}" \
     https://api.telemetry.confluent.cloud/v2/metrics/cloud/query \
        | jq .

# Write ksqlDB queries
MAX_WAIT=720
echo "Waiting up to $MAX_WAIT seconds for Confluent Cloud ksqlDB cluster to be UP"
retry $MAX_WAIT ccloud::validate_ccloud_ksqldb_endpoint_ready $KSQLDB_ENDPOINT

echo 
echo "Writing ksqlDB queries in Confluent Cloud"
ksqlDBAppId=$(confluent ksql app list | grep "$KSQLDB_ENDPOINT" | awk '{print $1}')
confluent ksql app describe $ksqlDBAppId -o json
confluent ksql app configure-acls $ksqlDBAppId wikipedia.parsed
while read ksqlCmd; do
  echo -e "\n$ksqlCmd\n"
  curl -X POST $KSQLDB_ENDPOINT/ksql \
       -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
       -u $KSQLDB_BASIC_AUTH_USER_INFO \
       --silent \
       -d @<(cat <<EOF
{
  "ksql": "$ksqlCmd",
  "streamsProperties": {}
}
EOF
)
done < ${VALIDATE_DIR}/statements.sql

echo
echo
echo "Confluent Cloud Environment:"
echo
echo "  export CONFIG_FILE=$CONFIG_FILE"
echo "  export SERVICE_ACCOUNT_ID=$SERVICE_ACCOUNT_ID"
echo "  export CCLOUD_CLUSTER_ID=$CCLOUD_CLUSTER_ID"
echo "  export METRICS_API_KEY=$METRICS_API_KEY"
echo "  export METRICS_API_SECRET=$METRICS_API_SECRET"
echo
echo "  export CURRENT_TIME_MINUS_1HR=$CURRENT_TIME_MINUS_1HR"
echo "  export CURRENT_TIME_PLUS_1HR=$CURRENT_TIME_PLUS_1HR"
echo


# Teardown
${VALIDATE_DIR}/destroy-ccloud-workflow.sh
