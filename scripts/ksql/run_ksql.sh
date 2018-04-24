#!/bin/bash

docker exec ksql-cli ksql-server-start /tmp/ksqlproperties 2>&1 &
sleep 10
docker exec ksql-cli bash -c "ksql http://localhost:8088 <<EOF
run script '/tmp/ksqlcommands';
exit ;
EOF
"
