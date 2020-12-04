#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

KAFKA_CLUSTER_ID=$(curl --insecure --location --request GET 'https://localhost:8091/kafka/v3/clusters' --header 'Authorization: Basic c3VwZXJVc2VyOnN1cGVyVXNlcg==' | jq -r '.data[0].cluster_id')

curl --insecure --location --request POST "https://localhost:8091/kafka/v3/clusters/${KAFKA_CLUSTER_ID}/topics" \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic c3VwZXJVc2VyOnN1cGVyVXNlcg==' \
--data-raw '{
    "topic_name": "users",
    "partitions_count": 2,
    "replication_factor": 2,
    "configs": [
        {
            "name": "confluent.value.schema.validation",
            "value": "true"
        }
    ]
}'

curl --insecure --location --request POST "https://localhost:8091/kafka/v3/clusters/${KAFKA_CLUSTER_ID}/topics" \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic c3VwZXJVc2VyOnN1cGVyVXNlcg==' \
--data-raw '{
    "topic_name": "wikipedia.parsed",
    "partitions_count": 2,
    "replication_factor": 2,
    "configs": [
        {
            "name": "confluent.value.schema.validation",
            "value": "true"
        }
    ]
}'

curl --insecure --location --request POST "https://localhost:8091/kafka/v3/clusters/${KAFKA_CLUSTER_ID}/topics" \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic c3VwZXJVc2VyOnN1cGVyVXNlcg==' \
--data-raw '{
    "topic_name": "wikipedia.parsed.count-by-domain",
    "partitions_count": 2,
    "replication_factor": 2
}'

curl --insecure --location --request POST "https://localhost:8091/kafka/v3/clusters/${KAFKA_CLUSTER_ID}/topics" \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic c3VwZXJVc2VyOnN1cGVyVXNlcg==' \
--data-raw '{
    "topic_name": "wikipedia.failed",
    "partitions_count": 2,
    "replication_factor": 2
}'

curl --insecure --location --request POST "https://localhost:8091/kafka/v3/clusters/${KAFKA_CLUSTER_ID}/topics" \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic c3VwZXJVc2VyOnN1cGVyVXNlcg==' \
--data-raw '{
    "topic_name": "WIKIPEDIABOT",
    "partitions_count": 2,
    "replication_factor": 2
}'

curl --insecure --location --request POST "https://localhost:8091/kafka/v3/clusters/${KAFKA_CLUSTER_ID}/topics" \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic c3VwZXJVc2VyOnN1cGVyVXNlcg==' \
--data-raw '{
    "topic_name": "WIKIPEDIANOBOT",
    "partitions_count": 2,
    "replication_factor": 2
}'

curl --insecure --location --request POST "https://localhost:8091/kafka/v3/clusters/${KAFKA_CLUSTER_ID}/topics" \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic c3VwZXJVc2VyOnN1cGVyVXNlcg==' \
--data-raw '{
    "topic_name": "EN_WIKIPEDIA_GT_1",
    "partitions_count": 2,
    "replication_factor": 2
}'

curl --insecure --location --request POST "https://localhost:8091/kafka/v3/clusters/${KAFKA_CLUSTER_ID}/topics" \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic c3VwZXJVc2VyOnN1cGVyVXNlcg==' \
--data-raw '{
    "topic_name": "EN_WIKIPEDIA_GT_1_COUNTS",
    "partitions_count": 2,
    "replication_factor": 2
}'
