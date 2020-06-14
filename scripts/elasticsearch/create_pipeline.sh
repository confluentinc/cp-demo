#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

curl --location --request PUT 'http://localhost:9200/_ingest/pipeline/wikipediabot-createdat-monthlyindex' \
--header 'Content-Type: application/json' \
--data-raw '{
  "description": "wikipediabot monthly CREATEDAT index naming",
  "processors" : [
    {
      "date_index_name" : {
        "field" : "CREATEDAT",
        "index_name_prefix" : "wikipediabot-",
        "date_rounding" : "M",
        "date_formats" : ["UNIX_MS"]
      }
    }
  ]
}'
