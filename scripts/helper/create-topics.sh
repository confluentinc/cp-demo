#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/functions.sh

KAFKA_CLUSTER_ID=$(curl -s --insecure --location --request GET 'https://localhost:8091/kafka/v3/clusters' --header 'Authorization: Basic c3VwZXJVc2VyOnN1cGVyVXNlcg==' | jq -r '.data[0].cluster_id')

echo "cluster_id: ${KAFKA_CLUSTER_ID}"

auth="superUser:superUser"

create_topic localhost:8091 ${KAFKA_CLUSTER_ID} users true ${auth}
create_topic localhost:8091 ${KAFKA_CLUSTER_ID} wikipedia.parsed true ${auth}
create_topic localhost:8091 ${KAFKA_CLUSTER_ID} wikipedia.parsed.count-by-domain false ${auth}
create_topic localhost:8091 ${KAFKA_CLUSTER_ID} wikipedia.failed false ${auth}
create_topic localhost:8091 ${KAFKA_CLUSTER_ID} WIKIPEDIABOT false ${auth}
create_topic localhost:8091 ${KAFKA_CLUSTER_ID} WIKIPEDIANOBOT false ${auth}
create_topic localhost:8091 ${KAFKA_CLUSTER_ID} EN_WIKIPEDIA_GT_1 false ${auth}
create_topic localhost:8091 ${KAFKA_CLUSTER_ID} EN_WIKIPEDIA_GT_1_COUNTS false ${auth}
