#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/functions.sh

KAFKA_CLUSTER_ID=$(get_kafka_cluster_id_from_container)

auth="superUser:superUser"

create_topic kafka1:8091 ${KAFKA_CLUSTER_ID} users true ${auth}
create_topic kafka1:8091 ${KAFKA_CLUSTER_ID} wikipedia.parsed true ${auth}
create_topic kafka1:8091 ${KAFKA_CLUSTER_ID} wikipedia.parsed.count-by-domain false ${auth}
create_topic kafka1:8091 ${KAFKA_CLUSTER_ID} wikipedia.failed false ${auth}
create_topic kafka1:8091 ${KAFKA_CLUSTER_ID} WIKIPEDIABOT false ${auth}
create_topic kafka1:8091 ${KAFKA_CLUSTER_ID} WIKIPEDIANOBOT false ${auth}
create_topic kafka1:8091 ${KAFKA_CLUSTER_ID} WIKIPEDIA_COUNT_GT_1 false ${auth}
