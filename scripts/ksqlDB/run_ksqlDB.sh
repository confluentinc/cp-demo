#!/bin/bash

# Cannot reliably use 'run script' until https://github.com/confluentinc/ksql/issues/4029 is resolved
docker-compose exec ksqldb-cli bash -c "/tmp/run_ksqlDB_commands.sh"
