{
    "topic_name": $topic_name,
    "partitions_count": 2,
    "replication_factor": 2,
    "configs": [
        {
            "name": "confluent.value.schema.validation",
            "value": $confluent_value_schema_validation
        }
    ]
}
