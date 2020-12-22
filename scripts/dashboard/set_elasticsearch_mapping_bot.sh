#!/bin/bash

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
    "order": 0,
    "version": 10000,
    "index_patterns": "wikipediabot",
    "settings": {
        "index": {
            "number_of_shards": 1,
            "number_of_replicas": 1,
            "refresh_interval": "10s",
            "codec": "best_compression"
        }
    },
    "mappings": {
        "_source" : {
            "enabled" : true
        },
        "properties": {
            "BOT": {
                "type": "boolean"
            },
            "BYTECHANGE": {
                "type": "long"
            },
            "COMMENT": {
                "type": "text"
            },
            "ID": {
                "type": "keyword"
            },
            "LENGTH": {
                "dynamic": true,
                "type": "object",
                "properties": {
                    "NEW": {
                        "type": "long"
                    },
                    "OLD": {
                        "type": "long"
                    }
                }
            },
            "LOG_ACTION": {
                "type": "keyword"
            },
            "LOG_ACTION_COMMENT": {
                "type": "keyword"
            },
            "LOG_ID": {
                "type": "keyword"
            },
            "LOG_TYPE": {
                "type": "keyword"
            },
            "META": {
                "dynamic": true,
                "type": "object",
                "properties": {
                    "DOMAIN": {
                        "type": "keyword"
                    },
                    "DT": {
                        "type": "date"
                    },
                    "ID": {
                        "type": "keyword"
                    },
                    "REQUEST_ID": {
                        "type": "keyword"
                    },
                    "STREAM": {
                        "type": "keyword"
                    },
                    "URI": {
                        "type": "keyword"
                    }
                }
            },
            "MINOR": {
                "type": "boolean"
            },
            "NAMESPACE": {
                "type": "keyword"
            },
            "PARSEDCOMMENT": {
                "type": "keyword"
            },
            "PATROLLED": {
                "type": "boolean"
            },
            "REVISION": {
                "dynamic": true,
                "type": "object",
                "properties": {
                    "NEW": {
                        "type": "keyword"
                    },
                    "OLD": {
                        "type": "keyword"
                    }
                }
            },
            "SERVER_NAME": {
                "type": "keyword"
            },
            "SERVER_SCRIPT_PATH": {
                "type": "keyword"
            },
            "SERVER_URL": {
                "type": "keyword"
            },
            "TIMESTAMP": {
                "type": "long"
            },
            "TITLE": {
                "type": "keyword"
            },
            "TYPE": {
                "type": "keyword"
            },
            "USER": {
                "type": "keyword"
            },
            "WIKI": {
                "type": "keyword"
            }
        }
    }
}
EOF
)

curl -XPUT -H "${HEADER}" --data "${DATA}" 'http://localhost:9200/_template/wikipediabot?pretty'
echo
