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
                "createdat": {
                    "type": "date"
                },
                "wikipage": {
                    "type": "keyword"
                },
                "isnew": {
                    "type": "boolean"
                },
                "isminor": {
                    "type": "boolean"
                },
                "isunpatrolled": {
                    "type": "boolean"
                },
                "isbot": {
                    "type": "boolean"
                },
                "diffurl": {
                    "type": "text"
                },
                "username": {
                    "type": "keyword"
                },
                "bytechange": {
                    "type": "integer"
                },
                "commitmessage": {
                    "type": "text"
                }
            }
        }
    }
}

EOF);

curl -XPUT -H "${HEADER}" --data "${DATA}" 'http://localhost:9200/wikipedia.parsed?pretty'
echo
