#!/bin/bash
  
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

ccloud login --save

CREDENTIALS=$(ccloud api-key create --resource cloud -o json) || exit 1

METRICS_API_KEY=$(echo "$CREDENTIALS" | jq -r .key)
METRICS_API_SECRET=$(echo "$CREDENTIALS" | jq -r .secret)

for broker in kafka1 kafka2; do
      docker-compose exec kafka1 kafka-configs \
        --bootstrap-server kafka1:12091 \
        --alter \
        --entity-type brokers \
        --entity-default \
        --add-config confluent.telemetry.enabled=true,confluent.telemetry.api.key="${METRICS_API_KEY}",confluent.telemetry.api.secret="${METRICS_API_SECRET}"
done

${DIR}/../scripts/setup-ccloud.sh
source "${DIR}/../scripts/delta-configs/env.delta"

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
