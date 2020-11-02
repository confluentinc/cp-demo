#!/bin/bash

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
    "settings": {
        "number_of_shards": 1
    },
    "mappings": {
        "wikichange": {
            "properties": {
                "META.DT": {
                    "type": "date"
                },
                "META.URI": {
                    "type": "keyword"
                },
                "BOT": {
                    "type": "boolean"
                },
                "USER": {
                    "type": "keyword"
                },
                "COMMENT": {
                    "type": "text"
                }
            }
        }
    }
}
EOF
)

curl -XPUT -H "${HEADER}" --data "${DATA}" 'http://localhost:9200/wikipediabot?pretty'
echo
