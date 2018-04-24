#!/bin/bash

KSQL_CONTAINER_NAME=$(docker-compose ps | grep ksql-cli | awk '{print $1}')

docker exec ${KSQL_CONTAINER_NAME} ksql-server-start /tmp/ksqlproperties 2>&1 &
sleep 10
docker exec ${KSQL_CONTAINER_NAME} bash -c "ksql http://localhost:8088 <<EOF
run script '/tmp/ksqlcommands';
exit ;
EOF
"
