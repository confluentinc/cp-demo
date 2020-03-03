#!/bin/bash

# Cannot reliably use 'run script' until https://github.com/confluentinc/ksql/issues/4029 is resolved
docker-compose exec ksql-cli bash -c "/tmp/run_ksql_commands.sh"
