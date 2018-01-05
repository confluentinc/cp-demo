#!/bin/bash

docker exec cpdemo_ksql-cli_1 ksql-server-start /tmp/ksqlproperties >/tmp/ksql.log 2>&1 &
sleep 10
docker-compose exec ksql-cli ksql-cli remote http://localhost:8080 --exec "run script '/tmp/ksqlcommands';" 
