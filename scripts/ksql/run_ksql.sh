#!/bin/bash

docker run -v $PWD/scripts/ksql/ksqlcommands:/tmp/ksqlcommands --network=cpdemo_default -i confluentinc/cp-ksql-cli:5.0.0-beta30 http://ksql-server:8088 <<EOF
run script '/tmp/ksqlcommands';
exit ;
EOF
