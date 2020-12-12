#!/bin/bash
  
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/../helper/functions.sh
${DIR}/../env.sh
source ${DIR}/../../.env

echo "DIR1: ${DIR}"

echo
echo "This example uses real Confluent Cloud resources."
echo "To avoid unexpected charges, carefully evaluate the cost of resources before launching the script and ensure all resources are destroyed after you are done running it."
echo "(Use Confluent Cloud promo ``C50INTEG`` to receive \$50 free usage)"
read -p "Do you still want to run this script? [y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  exit 1
fi

echo
ccloud login --save || exit 1

CREDENTIALS=$(ccloud api-key create --resource cloud -o json) || exit 1

METRICS_API_KEY=$(echo "$CREDENTIALS" | jq -r .key)
METRICS_API_SECRET=$(echo "$CREDENTIALS" | jq -r .secret)

#echo "METRICS_API_KEY: $METRICS_API_KEY"
#echo "METRICS_API_SECRET: $METRICS_API_SECRET"

echo
echo "Enabling Confluent Telemetry Reporter to send metrics to Confluent Cloud"
for brokerNum in 1 2; do
  docker-compose exec kafka${brokerNum} kafka-configs \
    --bootstrap-server kafka${brokerNum}:1209${brokerNum} \
    --alter \
    --entity-type brokers \
    --entity-default \
    --add-config "confluent.telemetry.enabled=true,confluent.telemetry.api.key='${METRICS_API_KEY}',confluent.telemetry.api.secret='${METRICS_API_SECRET}'"
done

# Create ccloud-stack
echo
echo "Configure a new Confluent Cloud ccloud-stack"
wget -O ccloud_library.sh https://raw.githubusercontent.com/confluentinc/examples/latest/utils/ccloud_library.sh
source ./ccloud_library.sh
ccloud::create_ccloud_stack
SERVICE_ACCOUNT_ID=$(ccloud kafka cluster list -o json | jq -r '.[0].name' | awk -F'-' '{print $4;}')
CONFIG_FILE=stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config

echo "DIR2: ${DIR}"

# Create parameters customized for Confluent Cloud instance created above
wget -O ccloud-generate-cp-configs.sh https://raw.githubusercontent.com/confluentinc/examples/latest/ccloud/ccloud-generate-cp-configs.sh
chmod 744 ./ccloud-generate-cp-configs.sh
./ccloud-generate-cp-configs.sh $CONFIG_FILE
source "delta_configs/env.delta"

echo -e "\nStart Confluent Replicator to Confluent Cloud:"
#docker-compose up -d replicator-to-ccloud
## Verify Confluent Replicator's Connect Worker has started
#MAX_WAIT=240
#echo -e "\nWaiting up to $MAX_WAIT seconds for Confluent Replicator's Connect Worker to start"
#retry $MAX_WAIT host_check_connect_up "replicator-to-ccloud" || exit 1
#sleep 2 # give connect an exta moment to fully mature

export REPLICATOR_NAME=replicate-topic-to-ccloud
# Create role binding
CONNECTOR_SUBMITTER="User:connectorSubmitter"
KAFKA_CLUSTER_ID=$(curl -s https://localhost:8091/v1/metadata/id --tlsv1.2 --cacert ${DIR}/../security/snakeoil-ca-1.crt | jq -r ".id")
CONNECT=connect-cluster
${DIR}/../helper/refresh_mds_login.sh
docker-compose exec tools bash -c "confluent iam rolebinding create \
    --principal $CONNECTOR_SUBMITTER \
    --role ResourceOwner \
    --resource Connector:${REPLICATOR_NAME} \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --connect-cluster-id $CONNECT"

# Either or
${DIR}/../connectors/submit_replicator_to_ccloud_config.sh
${DIR}/../connectors/submit_replicator_to_ccloud_config_backed_ccloud.sh

# Verify Replicator to Confluent Cloud has started
echo
MAX_WAIT=60
echo "Waiting up to $MAX_WAIT seconds for Replicator to Confluent Cloud to start"
retry $MAX_WAIT check_connector_status_running ${REPLICATOR_NAME} || exit 1
echo "Replicator started!"

echo "DIR3: ${DIR}"

DATA=$( cat << EOF
{
  "aggregations": [
      {
          "agg": "SUM",
          "metric": "io.confluent.kafka.server/received_bytes"
      }
  ],
  "granularity": "PT1M",
  "group_by": [
      "metric.label.topic"
  ],
  "limit": 5
}
EOF
)

curl -u ${METRICS_API_KEY}:${METRICS_API_SECRET} \
     --header 'content-type: application/json' \
     --data "${DATA}" \
     https://api.telemetry.confluent.cloud/v1/metrics/hosted-monitoring/query \
        | jq .


#### Disable ####

echo "DIR4: ${DIR}"
echo "Destroying all resources"

for brokerNum in 1 2; do
  docker-compose exec kafka${brokerNum} kafka-configs \
    --bootstrap-server kafka${brokerNum}:1209${brokerNum} \
        --alter \
        --entity-type brokers \
        --entity-default \
        --delete-config "confluent.telemetry.enabled,confluent.telemetry.api.key,confluent.telemetry.api.secret"
done

ccloud api-key delete $METRICS_API_KEY

ccloud::destroy_ccloud_stack $SERVICE_ACCOUNT_ID
echo "DIR4: ${DIR}"
