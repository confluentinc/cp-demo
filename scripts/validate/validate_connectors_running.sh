#!/bin/bash

for connector in wikipedia-irc replicate-topic elasticsearch-ksqldb; do
  STATE=$(docker-compose exec connect curl -X GET --cert /etc/kafka/secrets/connect.certificate.pem --key /etc/kafka/secrets/connect.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u superUser:superUser https://connect:8083/connectors/$connector/status | jq -r .connector.state)
  if [[ "$STATE" != "RUNNING" ]]; then
    echo "Connector $connector is in $STATE state but it should be in RUNNING.  Please troubleshoot. For troubleshooting instructions see https://docs.confluent.io/current/tutorials/cp-demo/docs/index.html#troubleshooting"
    exit 1
  else
    echo "Connector $connector is in $STATE state"
  fi
done

