#!/bin/bash

VALIDATE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

source ${VALIDATE_DIR}/../helper/functions.sh
source ${VALIDATE_DIR}/../../.env
source ${VALIDATE_DIR}/../env.sh

verify_installed ccloud || exit 1

curl -sS -o ccloud_library.sh https://raw.githubusercontent.com/confluentinc/examples/latest/utils/ccloud_library.sh
source ./ccloud_library.sh
ccloud::prompt_continue_ccloud_demo || exit 1

# Log into Confluent Cloud CLI
echo
ccloud login --save || exit 1

# Create credentials for the cloud resource
echo
CREDENTIALS=$(ccloud api-key create --resource cloud -o json) || exit 1
METRICS_API_KEY=$(echo "$CREDENTIALS" | jq -r .key)
METRICS_API_SECRET=$(echo "$CREDENTIALS" | jq -r .secret)
echo "export METRICS_API_KEY=$METRICS_API_KEY"
echo "export METRICS_API_SECRET=$METRICS_API_SECRET"

# Enable Confluent Telemetry Reporter
echo
echo "Enabling Confluent Telemetry Reporter cluster-wide to send metrics to Confluent Cloud"
docker-compose exec kafka1 kafka-configs \
  --bootstrap-server kafka1:12091 \
  --alter \
  --entity-type brokers \
  --entity-default \
  --add-config confluent.telemetry.enabled=true,confluent.telemetry.api.key=${METRICS_API_KEY},confluent.telemetry.api.secret=${METRICS_API_SECRET}

# Create a new ccloud-stack
echo
echo "Configure a new Confluent Cloud ccloud-stack (including a new ksqlDB application)"
ccloud::create_ccloud_stack true || exit 1
SERVICE_ACCOUNT_ID=$(ccloud kafka cluster list -o json | jq -r '.[0].name' | awk -F'-' '{print $4;}')
CONFIG_FILE=stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config
CCLOUD_CLUSTER_ID=$(ccloud kafka cluster list -o json | jq -c -r '.[] | select (.name == "'"demo-kafka-cluster-$SERVICE_ACCOUNT_ID"'")' | jq -r .id)
echo "CCLOUD_CLUSTER_ID=$CCLOUD_CLUSTER_ID"

# Create parameters customized for Confluent Cloud instance created above
curl -sS -o ccloud-generate-cp-configs.sh https://raw.githubusercontent.com/confluentinc/examples/latest/ccloud/ccloud-generate-cp-configs.sh
chmod 744 ./ccloud-generate-cp-configs.sh
./ccloud-generate-cp-configs.sh $CONFIG_FILE
source "delta_configs/env.delta"

echo
echo "Sleep an additional 60s to wait for all Confluent Cloud metadata to propagate"
sleep 60

echo -e "\nStart Confluent Replicator to Confluent Cloud:"
export REPLICATOR_NAME=replicate-topic-to-ccloud
CONNECTOR_SUBMITTER="User:connectorSubmitter"
KAFKA_CLUSTER_ID=$(curl -s https://localhost:8091/v1/metadata/id --tlsv1.2 --cacert ${VALIDATE_DIR}/../security/snakeoil-ca-1.crt | jq -r ".id")
CONNECT=connect-cluster
${VALIDATE_DIR}/../helper/refresh_mds_login.sh
docker-compose exec tools bash -c "confluent iam rolebinding create \
    --principal $CONNECTOR_SUBMITTER \
    --role ResourceOwner \
    --resource Connector:$REPLICATOR_NAME \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --connect-cluster-id $CONNECT"
${VALIDATE_DIR}/../connectors/submit_replicator_to_ccloud_config.sh

# Verify Replicator to Confluent Cloud has started
echo
echo
MAX_WAIT=120
echo "Waiting up to $MAX_WAIT seconds for Replicator to Confluent Cloud to start"
retry $MAX_WAIT check_connector_status_running $REPLICATOR_NAME || exit 1
echo "Replicator started!"
sleep 5

echo "Sleeping 90s to wait for Replicator to start propagating data to Confluent Cloud and for metrics collection to begin"
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
     https://api.telemetry.confluent.cloud/v1/metrics/hosted-monitoring/query \
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
     https://api.telemetry.confluent.cloud/v1/metrics/cloud/query \
        | jq .

#### Disable ####

echo
read -p "Do you want to destroy the Confluent Cloud resources and Replicator connector created by this validation script? [y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  exit 1
fi

echo "Destroying all Confluent Cloud resources"

docker-compose exec connect curl -XDELETE --cert /etc/kafka/secrets/connect.certificate.pem --key /etc/kafka/secrets/connect.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u connectorSubmitter:connectorSubmitter https://connect:8083/connectors/$REPLICATOR_NAME

docker-compose exec kafka1 kafka-configs \
  --bootstrap-server kafka1:12091 \
  --alter \
  --entity-type brokers \
  --entity-default \
  --delete-config confluent.telemetry.enabled,confluent.telemetry.api.key,confluent.telemetry.api.secret

ccloud api-key delete $METRICS_API_KEY

ccloud::destroy_ccloud_stack $SERVICE_ACCOUNT_ID
