#!/bin/bash

# Cannot reliably use 'run script' until https://github.com/confluentinc/ksql/issues/4029 is resolved
#docker-compose exec ksqldb-cli bash -c "/tmp/run_ksql_commands.sh"
docker-compose exec ksqldb-cli  bash -c "ksql -u ksqlDBUser -p ksqlDBUser http://ksqldb-server:8088 <<EOF
run script '/tmp/statements.sql';
exit ;
EOF
"
