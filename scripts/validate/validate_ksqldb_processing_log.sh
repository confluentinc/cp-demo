#!/bin/bash

# Run "bad" query
echo "Running 'bad' query (approximately 60 seconds)"
docker-compose exec ksqldb-cli bash -c "ksql -u ksqlDBUser -p ksqlDBUser http://ksqldb-server:8088 << EOF
SELECT ucase(cast(null as varchar)) FROM wikipedia EMIT CHANGES LIMIT 20;
exit ;
EOF"

# Read from ksqlDB processing log
echo "Reading from KSQL_PROCESSING_LOG (timeout 90 seconds)"
docker-compose exec ksqldb-cli bash -c "timeout 90 ksql -u ksqlDBUser -p ksqlDBUser http://ksqldb-server:8088 << EOF
SET 'auto.offset.reset'='earliest';
SET CLI COLUMN-WIDTH 20
SELECT * FROM KSQL_PROCESSING_LOG EMIT CHANGES LIMIT 20;
exit ;
EOF"
