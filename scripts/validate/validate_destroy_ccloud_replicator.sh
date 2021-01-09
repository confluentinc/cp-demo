#!/bin/bash

VALIDATE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

source ${VALIDATE_DIR}/../helper/functions.sh
source ${VALIDATE_DIR}/../../.env
source ${VALIDATE_DIR}/../env.sh

verify_installed ccloud || exit 1

if [ -z "$SERVICE_ACCOUNT_ID" ]; then
  echo "ERROR: Must export parameter SERVICE_ACCOUNT_ID before running this script (check your start workflow)."
  exit 1
fi
if [ -z "$METRICS_API_KEY" ]; then
  echo "ERROR: Must export parameter METRICS_API_KEY before running this script (check your start workflow)."
  exit 1
fi

curl -sS -o ccloud_library.sh https://raw.githubusercontent.com/confluentinc/examples/latest/utils/ccloud_library.sh
source ./ccloud_library.sh

# Log into Confluent Cloud CLI
echo
ccloud login --save || exit 1

#### Teardown ####

read -p "This script will remove Replicator and destroy all the resources (including the Confluent Cloud environment) for service account ID $SERVICE_ACCOUNT_ID.  Do you want to proceed? [y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  exit 1
fi

echo "Destroying all Confluent Cloud resources"

docker-compose exec connect curl -XDELETE --cert /etc/kafka/secrets/connect.certificate.pem --key /etc/kafka/secrets/connect.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u connectorSubmitter:connectorSubmitter https://connect:8083/connectors/replicate-topic-to-ccloud

docker-compose exec kafka1 kafka-configs \
  --bootstrap-server kafka1:12091 \
  --alter \
  --entity-type brokers \
  --entity-default \
  --delete-config confluent.telemetry.enabled,confluent.telemetry.api.key,confluent.telemetry.api.secret

ccloud api-key delete $METRICS_API_KEY

ccloud::destroy_ccloud_stack $SERVICE_ACCOUNT_ID
