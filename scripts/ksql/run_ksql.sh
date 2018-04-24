#!/bin/bash

docker exec cpdemo_ksql-cli_1 ksql-server-start /tmp/ksqlproperties 2>&1 &
sleep 10
docker exec cpdemo_ksql-cli_1 bash -c "ksql http://localhost:8088 <<EOF
run script '/tmp/ksqlcommands';
exit ;
EOF
"
