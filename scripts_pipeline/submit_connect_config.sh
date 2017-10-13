#!/bin/bash

if [[ $2 ]];then
    CONNECT_HOST=$1
    INPUT_FILE=$2
else
    CONNECT_HOST=localhost:8083
    INPUT_FILE=$1
fi


if [[ ! -f $INPUT_FILE ]]; then
  echo "ERROR: Input file ${INPUT_FILE} not found!";
fi

HEADER="Content-Type: application/json"


echo "curl -s -X POST -H \"${HEADER}\" --data @${INPUT_FILE} http://${CONNECT_HOST}/connectors"
curl -s -X POST -H "${HEADER}" --data @${INPUT_FILE} http://${CONNECT_HOST}/connectors
echo
