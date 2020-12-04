#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

KAFKA_CLUSTER_ID=$(curl --insecure --location --request GET 'https://localhost:8091/kafka/v3/clusters' --header 'Authorization: Basic c3VwZXJVc2VyOnN1cGVyVXNlcg==' | jq -r '.data[0].cluster_id')

curl --insecure --location --request POST "https://localhost:8091/kafka/v3/clusters/${KAFKA_CLUSTER_ID}/topics" \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic c3VwZXJVc2VyOnN1cGVyVXNlcg==' \
--data-binary @<(jq -n --arg topic_name users --arg confluent_value_schema_validation "true" -f ${DIR}/topic.jq)

curl --insecure --location --request POST "https://localhost:8091/kafka/v3/clusters/${KAFKA_CLUSTER_ID}/topics" \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic c3VwZXJVc2VyOnN1cGVyVXNlcg==' \
--data-binary @<(jq -n --arg topic_name "wikipedia.parsed" --arg confluent_value_schema_validation "true" -f ${DIR}/topic.jq)

curl --insecure --location --request POST "https://localhost:8091/kafka/v3/clusters/${KAFKA_CLUSTER_ID}/topics" \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic c3VwZXJVc2VyOnN1cGVyVXNlcg==' \
--data-binary @<(jq -n --arg topic_name "wikipedia.parsed.count-by-domain" --arg confluent_value_schema_validation "false" -f ${DIR}/topic.jq)

curl --insecure --location --request POST "https://localhost:8091/kafka/v3/clusters/${KAFKA_CLUSTER_ID}/topics" \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic c3VwZXJVc2VyOnN1cGVyVXNlcg==' \
--data-binary @<(jq -n --arg topic_name "wikipedia.failed" --arg confluent_value_schema_validation "false" -f ${DIR}/topic.jq)

curl --insecure --location --request POST "https://localhost:8091/kafka/v3/clusters/${KAFKA_CLUSTER_ID}/topics" \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic c3VwZXJVc2VyOnN1cGVyVXNlcg==' \
--data-binary @<(jq -n --arg topic_name "WIKIPEDIABOT" --arg confluent_value_schema_validation "false" -f ${DIR}/topic.jq)

curl --insecure --location --request POST "https://localhost:8091/kafka/v3/clusters/${KAFKA_CLUSTER_ID}/topics" \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic c3VwZXJVc2VyOnN1cGVyVXNlcg==' \
--data-binary @<(jq -n --arg topic_name "WIKIPEDIANOBOT" --arg confluent_value_schema_validation "false" -f ${DIR}/topic.jq)

curl --insecure --location --request POST "https://localhost:8091/kafka/v3/clusters/${KAFKA_CLUSTER_ID}/topics" \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic c3VwZXJVc2VyOnN1cGVyVXNlcg==' \
--data-binary @<(jq -n --arg topic_name "EN_WIKIPEDIA_GT_1" --arg confluent_value_schema_validation "false" -f ${DIR}/topic.jq)

curl --insecure --location --request POST "https://localhost:8091/kafka/v3/clusters/${KAFKA_CLUSTER_ID}/topics" \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic c3VwZXJVc2VyOnN1cGVyVXNlcg==' \
--data-binary @<(jq -n --arg topic_name "EN_WIKIPEDIA_GT_1_COUNTS" --arg confluent_value_schema_validation "false" -f ${DIR}/topic.jq)
