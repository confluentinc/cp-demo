#!/bin/bash
  
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

ccloud login --save

CREDENTIALS=$(ccloud api-key create --resource cloud -o json) || exit 1

METRICS_API_KEY=$(echo "$CREDENTIALS" | jq -r .key)
METRICS_API_SECRET=$(echo "$CREDENTIALS" | jq -r .secret)

echo "METRICS_API_KEY: $METRICS_API_KEY"
echo "METRICS_API_SECRET: $METRICS_API_SECRET"

for brokerNum in 1 2; do
  docker-compose exec kafka${brokerNum} kafka-configs \
    --bootstrap-server kafka${brokerNum}:1209${brokerNum} \
    --alter \
    --entity-type brokers \
    --entity-default \
    --add-config "confluent.telemetry.enabled=true,confluent.telemetry.api.key='${METRICS_API_KEY}',confluent.telemetry.api.secret='${METRICS_API_SECRET}'"
done

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

# Create ccloud-stack
wget -O ccloud_library.sh https://raw.githubusercontent.com/confluentinc/examples/latest/utils/ccloud_library.sh
source ./ccloud_library.sh
ccloud::create_ccloud_stack
SERVICE_ACCOUNT_ID=$(ccloud kafka cluster list -o json | jq -r '.[0].name' | awk -F'-' '{print $4;}')
CONFIG_FILE=stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config

# Create parameters customized for Confluent Cloud instance created above
wget -O ccloud-generate-cp-configs.sh https://raw.githubusercontent.com/confluentinc/examples/latest/ccloud/ccloud-generate-cp-configs.sh
./ccloud-generate-cp-configs.sh $CONFIG_FILE
source "${DIR}/../helper/delta-configs/env.delta"

echo -e "\nStart Confluent Replicator to Confluent Cloud:"
${DIR}/../connectors/submit_replicator_to_ccloud_config.sh

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

for brokerNum in 1 2; do
  docker-compose exec kafka${brokerNum} kafka-configs \
    --bootstrap-server kafka${brokerNum}:1209${brokerNum} \
        --alter \
        --entity-type brokers \
        --entity-default \
        --delete-config "confluent.telemetry.enabled=true,confluent.telemetry.api.key='${METRICS_API_KEY}',confluent.telemetry.api.secret='${METRICS_API_SECRET}'"
done

ccloud api-key delete $METRICS_API_KEY

ccloud::destroy_ccloud_stack $SERVICE_ACCOUNT_ID
