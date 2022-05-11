#!/bin/bash

VALIDATE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

source ${VALIDATE_DIR}/../helper/functions.sh

verify_installed confluent || exit 1

if [ -z "$SERVICE_ACCOUNT_ID" ]; then
  echo "ERROR: Must export parameter SERVICE_ACCOUNT_ID before running this script to destroy Confluent Cloud resources associated to that service account."
  exit 1
fi
if [ -z "$METRICS_API_KEY" ]; then
  echo "ERROR: Must export parameter METRICS_API_KEY before running this script to destroy the API key created for the Telemetry Reporter."
  exit 1
fi

curl -sS -o ccloud_library.sh https://raw.githubusercontent.com/confluentinc/examples/latest/utils/ccloud_library.sh
source ./ccloud_library.sh

# Log into Confluent CLI
echo
confluent login --save || exit 1

#### Teardown ####

echo
read -p "This script will destroy the Confluent Cloud environment for service account ID $SERVICE_ACCOUNT_ID.  Do you want to proceed? [y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo
  echo "--> Don't forget to destroy your Confluent Cloud environment, which may accrue hourly charges even if you are not actively using it."
  echo
  exit 1
fi


## TODO delete CP cluster link
# echo "Deleting Cluster Link to Confluent Cloud"
# docker-compose exec connect curl -XDELETE --cert /etc/kafka/secrets/connect.certificate.pem --key /etc/kafka/secrets/connect.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u connectorSubmitter:connectorSubmitter https://connect:8083/connectors/replicate-topic-to-ccloud

echo "Unconfiguring Telemetry Reporter"
docker-compose exec kafka1 kafka-configs \
  --bootstrap-server kafka1:12091 \
  --alter \
  --entity-type brokers \
  --entity-default \
  --delete-config confluent.telemetry.enabled,confluent.telemetry.api.key,confluent.telemetry.api.secret

echo "Destroying all Confluent Cloud resources"
confluent api-key delete $METRICS_API_KEY
source "delta_configs/env.delta"
ccloud::destroy_ccloud_stack $SERVICE_ACCOUNT_ID

echo
