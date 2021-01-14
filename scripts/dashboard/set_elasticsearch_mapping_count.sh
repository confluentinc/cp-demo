#!/bin/bash

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
    "order": 0,
    "version": 10000,
    "index_patterns": "wikipedia_count_gt_*",
    "settings": {
        "index": {
            "number_of_shards": 1,
            "number_of_replicas": 1,
            "refresh_interval": "10s",
            "codec": "best_compression"
        }
    },
    "mappings": {
        "properties": {
            "META": {
                "dynamic": true,
                "type": "object",
                "properties": {
                    "URI": {
                        "type": "keyword"
                    }
                }
            },
            "USER": {
                "type": "keyword"
            },
            "COUNT": {
                "type": "long"
            }
        }
    }
}
EOF
)

curl -XPUT -H "${HEADER}" --data "${DATA}" 'http://localhost:9200/_template/wikipedia_count_gt?pretty'
echo
