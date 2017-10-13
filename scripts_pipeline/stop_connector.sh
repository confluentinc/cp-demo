#!/bin/bash

if [[ $2 ]];then
    CONNECT_HOST=$1
    CONNECTOR_NAME=$2
else
    CONNECT_HOST=localhost:8083
    CONNECTOR_NAME=$1
fi

CONNECTOR_EXISTS=$(curl -s http://${CONNECT_HOST}/connectors | grep "${CONNECTOR_NAME}")
echo $CONNECTOR_EXISTS
if [[ ! ${CONNECTOR_EXISTS} ]]; then
  echo "ERROR: ${CONNECTOR_NAME} not found on ${CONNECT_HOST}";
  exit 1;
fi

URL=http://${CONNECT_HOST}/connectors/${CONNECTOR_NAME}
echo "curl -X DELETE ${URL}"
curl -s -X DELETE ${URL}
echo
