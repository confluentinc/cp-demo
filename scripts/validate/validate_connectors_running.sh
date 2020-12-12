#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/../helper/functions.sh

for connector in wikipedia-sse replicate-topic elasticsearch-ksqldb; do
  check_connector_status_running $connector
  status=$?
  if [[ $status == "0" ]]; then
    echo "Connector $connector is in $STATE state"
  else
    if ! [[ "$connector" -eq "elasticsearch-ksqldb" ]]; then
      echo "Connector $connector is in $STATE state but it should be in RUNNING.  Please troubleshoot. For troubleshooting instructions see https://docs.confluent.io/current/tutorials/cp-demo/docs/index.html#troubleshooting"
      exit 1
    else
      echo "Connector $connector is in $STATE state but it should be in RUNNING (unless VIZ=false)"
    fi
  fi
done

exit 0

