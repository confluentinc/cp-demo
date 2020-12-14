#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

curl -XPOST "http://localhost:5601/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" -H "securitytenant: global" --form file=@${DIR}/cp-demo.ndjson
